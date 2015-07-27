class RsvpReportMailer < ActionMailer::Base
  default from: 'support@brandscopic.com'

  def file_missing
    recipients = ENV['RSVP_FILE_MISSING_EMAILS'].split(',')
    mail to: recipients, subject: 'RSVP Report Synch – File Not Found'
  end

  def invalid_format(files, columns, invalid_columns)
    recipients = ENV['RSVP_INVALID_FORMAT_EMAILS'].split(',')
    @columns = columns
    @invalid_columns = invalid_columns
    files.each do |path|
      attachments[File.basename(path)] = File.read(path)
    end
    mail to: recipients, subject: 'RSVP Report Synch – Improper Format'
  end

  def success(created, failed, multiple_events, files = [])
    @created = created
    @failed = failed
    @multiple_events = multiple_events
    recipients = ENV['RSVP_SUCCESS_EMAILS'].split(',')

    files.each do |path|
      attachments[File.basename(path)] = File.read(path)
    end if files

    mail to: recipients, subject: 'RSVP Report Synch – Successfully Completed'
  end

  def fail(failed, error_messages, files = [])
    @failed = failed
    @error_messages = error_messages
    recipients = ENV['RSVP_SUCCESS_EMAILS'].split(',')

    files.each do |path|
      attachments[File.basename(path)] = File.read(path)
    end if files

    mail to: recipients, subject: 'RSVP Report Synch – Failed'
  end
end
