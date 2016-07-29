module RedmineExtensions
  class DateRange < Hash

    def self.first_wday
      case Setting.start_of_week.to_i
      when 1, 6, 7
        Setting.start_of_week.to_i
      else
        (I18n.t(:general_first_day_of_week).to_i - 1)%7 + 1
      end
    end

    def self.get_date_range(period_type = '1', period = 'all', from = '', to = '')
      @free_period = false
      start_of_week = self.first_wday

      ret = {:from => nil, :to => nil}

      if period_type == '1' || (period_type.nil? && !period.nil?)
        case period
          when 'all', 'is_null', 'is_not_null'

          when 'today'
            ret[:from] = ret[:to] = User.current.today
          when 'yesterday'
            ret[:from] = ret[:to] = User.current.today - 1
          when 'current_week'
            ret[:from] = User.current.today - (User.current.today.cwday - start_of_week)%7
            ret[:to] = ret[:from] + 6
          when 'last_week'
            ret[:from] = User.current.today - 7 - (User.current.today.cwday - start_of_week)%7
            ret[:to] = ret[:from] + 6
          when 'last_2_weeks'
            ret[:from] = User.current.today - 14 - (User.current.today.cwday - start_of_week)%7
            ret[:to] = ret[:from] + 13
          when '7_days'
            ret[:from] = User.current.today - 7
            ret[:to] = User.current.today
          when 'current_month'
            ret[:from] = Date.civil(User.current.today.year, User.current.today.month, 1)
            ret[:to] = (ret[:from] >> 1) - 1
          when 'last30_next90'
            ret[:from] = User.current.today - 30
            ret[:to] = User.current.today + 90
          when 'last_month'
            ret[:from] = Date.civil(User.current.today.year, User.current.today.month, 1) << 1
            ret[:to] = (ret[:from] >> 1) - 1
          when '30_days'
            ret[:from] = User.current.today - 30
            ret[:to] = User.current.today
          when '90_days'
            ret[:from] = User.current.today - 90
            ret[:to] = User.current.today
          when 'current_year'
            ret[:from] = Date.civil(User.current.today.year, 1, 1)
            ret[:to] = Date.civil(User.current.today.year, 12, 31)
          when 'last_year'
            ret[:from] = Date.civil(User.current.today.year - 1, 1, 1)
            ret[:to] = Date.civil(User.current.today.year - 1, 12, 31)
          when 'older_than_14_days'
            ret[:from] = nil
            ret[:to] = User.current.today - 14
          when 'older_than_15_days'
            ret[:from] = nil
            ret[:to] = User.current.today - 15
          when 'older_than_31_days'
            ret[:from] = nil
            ret[:to] = User.current.today - 31
          ### FUTURE ###
          when 'tomorrow'
            ret[:from] = ret[:to] = Date.tomorrow
          when 'next_week'
            ret[:from] = User.current.today + 7 - (User.current.today.cwday - start_of_week)%7
            ret[:to] = ret[:from] + 6
          when 'next_5_days'
            ret[:from] = User.current.today
            ret[:to] = User.current.today + 5
          when 'next_7_days'
            ret[:from] = User.current.today
            ret[:to] = User.current.today + 7
          when 'next_10_days'
            ret[:from] = User.current.today
            ret[:to] = User.current.today + 10
          when 'next_14_days'
            ret[:from] = User.current.today
            ret[:to] = User.current.today + 14
          when 'next_15_days'
            ret[:from] = User.current.today
            ret[:to] = User.current.today + 15
          when 'next_30_days'
            ret[:from] = User.current.today
            ret[:to] = User.current.today + 30
          when 'next_90_days'
            ret[:from] = User.current.today
            ret[:to] = User.current.today + 90
          when 'next_month'
            ret[:from] = Date.civil(User.current.today.year, User.current.today.month, 1) >> 1
            ret[:to] = (ret[:from] >> 1) - 1
          when 'next_year'
            ret[:from] = Date.civil(User.current.today.year + 1, 1, 1)
            ret[:to] = Date.civil(User.current.today.year + 1, 12, 31)
          ### EXTENDED ###
          when 'to_today'
            ret[:from] = nil
            ret[:to] = User.current.today
          when 'from_tomorrow'
            ret[:from] = Date.tomorrow
            ret[:to] = nil
          when 'after_due_date'
            ret[:from] = nil
            ret[:to] = Date.yesterday
          ### FISCAL ###
          when 'last_fiscal_year'
            ret[:from] = EasySetting.beginning_of_fiscal_year(User.current.today - 1.year)
            ret[:to] = EasySetting.end_of_fiscal_year(User.current.today - 1.year)
          when 'current_fiscal_year'
            ret[:from] = EasySetting.beginning_of_fiscal_year
            ret[:to] = EasySetting.end_of_fiscal_year
          when 'next_fiscal_year'
            ret[:from] = EasySetting.beginning_of_fiscal_year(User.current.today + 1.year)
            ret[:to] = EasySetting.end_of_fiscal_year(User.current.today + 1.year)
          else
            if respond_to?("hook_#{period}")
              ret = send("hook_#{period}")
            else
              Rails.logger.warn "You must add '#{period}' to 'utils/dateutils' !" if Rails.logger
            end
        end
      elsif period_type == '2' || (period_type.nil? && (!from.nil? || !to.nil?))
        begin
          ret[:from] = from.to_s.to_date unless from.blank?
        rescue
        end
        begin
          ret[:to] = to.to_s.to_date unless to.blank?
        rescue
        end
        @free_period = true
      end

      ret[:from], ret[:to] = ret[:to], ret[:from] if ret[:from] && ret[:to] && ret[:from] > ret[:to]

      ret
    end

    def initialize(period_type = '1', period = 'all', from = '', to = '')
      super()
      self.merge!(self.class.get_date_range(period_type, period, from, to))
    end

  end
end
