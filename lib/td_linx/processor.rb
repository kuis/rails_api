require 'net/ftp'
require 'zip'
require 'open-uri'
require 'tempfile'

module TdLinxSynch
  class Processor
    attr_accessor :csv_path

    def self.download_and_process_file(file)
      path = file || 'tmp/td_linx_code.csv'
      unless file
        download_file(path)
      end
      process(path)
    rescue => e
      TdlinxMailer.td_linx_process_failed(e).deliver
      raise e # Raise the error so we see it on errbit
    end

    def self.process(path)
      paths = {
        master_only: 'tmp/td_master_only.csv',
        brandscopic_only: 'tmp/brandscopic_only.csv',
        found: 'tmp/found_and_updated.csv',
        found_not_updated: 'tmp/found_not_updated.csv',
        missing: 'tmp/missing.csv'
      }

      # Create and open all CSV files
      files = Hash[paths.map { |k, p| [k, CSV.open(p, 'w')] }]

      # Here it comes... read each line in the downloaded CSV file
      # and look for a match in the database
      CSV.foreach(path) do |row|
        row[2].gsub!(/,\s*#{row[3]}\s*,\s*#{row[4]}\s*,\s*#{row[5]}\s*/, '')
        row[2].gsub!(/\A\s*#{row[1]}\s*,?\s*/, '')
        if place_id = find_place_for_row(row)
          place = Place.find(place_id)
          if place.td_linx_code != row[0]
            files[:found] << row + [place.td_linx_code]
            place.update_column(:td_linx_code, row[0])
          else
            files[:found_not_updated] << row
          end
        else
          files[:master_only] << row
        end
      end

      # Search for establishments related to venues in LegacyCompany that doesn't
      # have a code and add it to missing.csv file
      files[:missing] << ['Venue Name', 'Street', 'City', 'State', 'Zip Code', '# Events']
      Place.joins(:venues).joins('LEFT JOIN events ON events.place_id=places.id')
           .select('places.*, count(events.id) as visits_count')
           .group('places.id')
           .where('venues.company_id=2 AND td_linx_code is null')
           .where('types like \'%establishment%\'')
           .find_each do |place|
        files[:missing] << [place.name, place.street, place.city, place.state, place.zipcode, place.visits_count]
      end
      files.each { |_k, file| file.close }

      zip_path = Dir::Tmpname.make_tmpname('tmp/tdlinx_', nil)
      Zip::File.open(zip_path, Zip::File::CREATE) do |zip|
        paths.each { |_k, path|  zip.add(File.basename(path), path) }
      end

      TdlinxMailer.td_linx_process_completed(zip_path).deliver

      files = {}
      File.delete zip_path
      paths
    ensure
      files.each { |_k, file| file.close rescue true }
    end

    def self.find_place_for_row(row)
      Place.find_tdlinx_place(name: row[1].try(:strip), street: row[2].try(:strip), city: row[3].try(:strip),
        state: state_name(row[4].try(:strip)), zipcode: row[5].try(:strip))
    end

    def self.state_name(state_code)
      state_code.match(/\A[A-Z]{2}\z/i) ? country.states[state_code]['name'] : state_code
    end

    protected

    def self.country
      @country ||= Country.new('US')
    end

    def self.download_file(path)
      ftp = Net::FTP.new(ENV['TDLINX_FTP_SERVER'])
      ftp.passive = true
      ftp.login(ENV['TDLINX_FTP_USERNAME'], ENV['TDLINX_FTP_PASSWORD'])
      file = ftp.list('Legacy_TDLINX_Store_Master*').map { |l| l.split(/\s+/, 4) }.sort { |a, b| b[0] <=> a[0] }.first
      if file.present?
        ftp.gettextfile file[3], path
      end
      ftp.close
    end
  end
end
