require 'dotenv/load'
require 'mqtt'
require 'influxdb'
require 'json'
require 'date'

def db_data(packet)
    return nil if packet.topic.count('/') != 1

    begin
        payload = JSON.parse(packet.payload)
    rescue JSON::ParserError
       return nil
    end

    return nil if payload.empty? || (!payload["timestamp"].nil? && payload.size == 1) 

    values = {}

    payload.each do |k, v|
        next if k == "timestamp"

        if v.is_a?(Integer) || v.is_a?(Float)
            values[k.to_sym] = v
        end
    end

    timestamp = if payload["timestamp"].nil?
        Time.now.to_i
    else
        DateTime.parse(payload["timestamp"]).to_time.to_i
    end

    data = {
        series: packet.topic,
        values: values,
        timestamp: timestamp
    }
end

def log_data(data, logger)
    log_msg = "Received a message by topic [#{data[:series]}]\n"
    log_msg << "Data timestamp is: #{Time.at(data[:timestamp])}\n"

    data[:values].each do |key, value|
        log_msg << "#{data[:series]}.#{key} #{value}\n"
    end

    logger.print log_msg
end

mqtt = MQTT::Client.connect(:host => ENV['BROKER_HOST'], :port => ENV['BROKER_PORT'])
mqtt.subscribe('#')

influxdb = InfluxDB::Client.new ENV['DB_NAME'], host: ENV['DB_HOST']

logger = nil
if ENV['DEBUG_DATA_FLOW']
    fd = IO.sysopen("/proc/1/fd/1", "w")
    logger = IO.new(fd, "w")
    logger.sync = true
end

mqtt.get_packet do |packet|
    data = db_data(packet)
    unless data.nil?
        influxdb.write_points(data, precision = ENV['PRECISION'])
        log_data(data, logger) if ENV['DEBUG_DATA_FLOW']
    end
end

