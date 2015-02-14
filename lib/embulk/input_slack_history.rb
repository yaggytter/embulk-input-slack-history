module Embulk
  module Plugin

    require 'json'
    require 'rest-client'

    class SlackApiException < Exception; end

    class SlackApi

      def initialize(token)
        @token = token
        @members = {}
        @groups = {}
        @channels = {}
      end

      def pre()

        # TODO: need implement error handling
        # HTTP Status Code
        # RestClient Exception
        # result is NOT 'ok'

        json = RestClient.get('https://slack.com/api/channels.list', {:params => {'token' => @token, 'pretty' => 1}})
        result = JSON.parse(json)

        if !result['ok'] then
          raise SlackApiException
        end

        result["channels"].each{|channel|
          @channels[channel["id"]] = channel["name"]
        }

        json = RestClient.get('https://slack.com/api/groups.list', {:params => {'token' => @token, 'pretty' => 1}})
        result = JSON.parse(json)

        if !result['ok'] then
          raise SlackApiException
        end

        result["groups"].each{|group|
          @groups[group["id"]] = group["name"]
        }

        json = RestClient.get('https://slack.com/api/users.list', {:params => {'token' => @token, 'pretty' => 1}})
        result = JSON.parse(json)

        if !result['ok'] then
          raise SlackApiException
        end

        result["members"].each{|member|
          @members[member["id"]] = member["name"]
        }

        return true

      end
      
      def parse_history(message)

        res = {}

        res["ts"] = message["ts"]
        res["username"] = @members[message["user"]]
        res["userid"] = message["user"]
        res["message"] = message["text"]

        return res

      end

      def get_oldest_filepath(filepath, channelid)
        return filepath + "/" + channelid + ".oldest"
      end

      def get_continuous_param(continuous, filepath, channelid)

        if !continuous then
          return ""
        end

        param = ""

        fullpath = get_oldest_filepath(filepath, channelid)

        if !File.exist?(fullpath) then
          return ""
        end        

        line = File.read(fullpath)

        param = "&oldest=" + line + "&inclusive=0"

        return param

      end

      def update_oldest(continuous, filepath, channelid, newest)

        if !continuous || newest == 0.0 then
          return
        end        

        fullpath = get_oldest_filepath(filepath, channelid)
        File.write(fullpath, newest)

      end

      def get_history_by_channels(continuous, filepath, channels, isprivate)

        res = []
        i = 0

        channels.each{|id, name|

          api = "channels"
          if isprivate == "yes" then
            api = "groups"
          end

          param = get_continuous_param(continuous, filepath, id)

          json = RestClient.get('https://slack.com/api/' + api + '.history', {:params => {'token' => @token, 'channel' => id, 'pretty' => 1}})
          result = JSON.parse(json)

          newest = 0.0

          result["messages"].each{|message|

            mes = parse_history(message)
            mes["channelid"] = id
            mes["channelname"] = name
            mes["private"] = isprivate
            res[i] = mes
            i += 1

            ts = message['ts'].to_f
            if newest < ts then
              newest = ts
            end

          }

          update_oldest(continuous, filepath, id, newest)

        }

        return res

      end

      def get_history(continuous, filepath)

        res = get_history_by_channels(continuous, filepath, @channels, "no")
        res.concat(get_history_by_channels(continuous, filepath, @groups, "yes"))

        return res

      end


    end

    class InputSlackHistory < InputPlugin

      # input plugin file name must be: embulk/input_<name>.rb
      Plugin.register_input('slack_history', self)

      def self.transaction(config, &control)

        @noerror = true

        threads = 1

        token = config.param('token', :string)
        continuous = config.param('continuous', :bool, default: false)
        filepath = config.param('filepath', :string, default: '/tmp')
        preview = config.param('preview', :string, default: 'no')

        task = {
          'token' => token,
          'continuous' => continuous,
          'filepath' => filepath,
          'preview' => preview
        }

        columns = [
          Column.new(0, 'channelid', :string),
          Column.new(1, 'channelname', :string),
          Column.new(2, 'private', :string),
          Column.new(3, 'datetime', :timestamp),
          Column.new(4, 'username', :string),
          Column.new(5, 'userid', :string),
          Column.new(6, 'message', :string),
        ]

        puts "Slack history input started."
        commit_reports = yield(task, columns, threads)
        puts "Slack history input finished."

        next_config_diff = {}
        return next_config_diff

      end


      def initialize(task, schema, index, page_builder)
        super
        @slack = SlackApi.new(task['token'])
        @noerror = @slack.pre()
      end

      def run

        if !@noerror then
          @page_builder.finish
          return
        end

        messages = @slack.get_history(@task['continuous'], @task['filepath'])

        messages.each{|message|
          @page_builder.add([
            message['channelid'],
            message['channelname'],
            message['private'],
            Time.at(message['ts'].to_f),
            message['username'],
            message['userid'],
            message['message']
            ])
        }

        @page_builder.finish

        commit_report = {}
        return commit_report
      end

    end

  end
end
