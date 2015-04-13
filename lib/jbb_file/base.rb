module JbbFile
  class Base
    COMPANY_ID = 2

    attr_accessor :ftp_username, :ftp_password, :ftp_server, :ftp_folder,
                  :mailer, :invalid_files

    def valid_format?(file)
      valid = false
      each_sheet(file) do |sheet|
        unless (self.class::VALID_COLUMNS - sheet.row(1)).empty?
          p self.class::VALID_COLUMNS - sheet.row(1)
          return false
        end
        valid = true
      end
      valid
    end

    def download_files(dir)
      files = find_files
      unless files.any?
        file_not_fould
        return files
      end
      files.map do |file_name|
        file = get_file(dir, file_name)
        if valid_format?(file[:excel])
          file
        else
          @invalid_files.push temp_file_path(dir, file_name)
          nil
        end
      end.compact
    ensure
      p "closing connection"
      close_connection
    end

    def archive_file(file)
      begin
        ftp_connecion.mkdir('OLD') unless ftp_connecion.list("*").any? { |dir| dir.match(/\sOLD$/) }
      rescue Net::FTPPermError
        p "Archive directory already exists"
      end
      ftp_connecion.rename(file, "OLD/#{file}")
    end

    def get_file(dir, file)
      path = temp_file_path(dir, file)
      ftp_connecion.getbinaryfile file, path
      { path: path, file_name: file, excel: Roo::Excelx.new(path) }
    end

    def temp_file_path(dir, name)
      "#{dir}/#{name}"
    end

    def each_sheet(file, &block)
      file.instance_variable_get(:@workbook_doc).xpath("//xmlns:sheet").each do |s|
        next if s.attributes['state'].to_s == 'hidden' # Ignore hidden sheets
        file.default_sheet = s['name']
        yield file
      end
    end

    def file_not_fould
      mailer.file_missing.deliver
      false
    end

    def close_connection
      return unless @ftp_connecion
      @ftp_connecion.close
      @ftp_connecion = nil
    end

    def invalid_format
      mailer.invalid_format(self.invalid_files).deliver
      false
    end

    def ftp_connecion
      @ftp_connecion = nil if @ftp_connecion && @ftp_connecion.closed?
      @ftp_connecion ||= Net::FTP.new(ftp_server).tap do |ftp|
        ftp.passive = true
        ftp.login(ftp_username, ftp_password)
        ftp.chdir(ftp_folder) if ftp_folder
        ftp.binary = true
        ftp
      end
    end

    def find_files
      ftp_connecion.nlst('*xlsx')
    rescue Net::FTPTempError
      []
    end
  end
end
