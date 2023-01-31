class ApplicationService
  attr_reader :error, :data

  def self.call(...)
    instance = new(...)
    instance.call
    instance
  rescue => e
    instance.send(:fail!, error: e.message)
    instance
  end

  def success?
    error.nil?
  end

  protected

  def success(data: nil)
    @data = data
  end

  alias success! success

  def fail(data: nil, error: )
    @data = data
    @error = error
  end

  alias fail! fail
end