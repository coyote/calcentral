module CampusOracle
  class UserAttributes < BaseProxy
    include Cache::UserCacheExpiry

    def initialize(options = {})
      super(Settings.sakai_proxy, options)
    end

    def get_feed
      # Because this data structure is used by multiple top-level feeds, it's essential
      # that it be cached efficiently.
      self.class.fetch_from_cache @uid do
        get_feed_internal
      end
    end

    # TODO Eliminate mix of string keys and symbol keys.
    def get_feed_internal
      result = CampusOracle::Queries.get_person_attributes(@uid)
      if result
        result[:reg_status] = {
          :code => result["reg_status_cd"],
          :summary => reg_status_translator.status(result["reg_status_cd"]),
          :explanation => reg_status_translator.status_explanation(result["reg_status_cd"]),
          :needsAction => !reg_status_translator.is_registered(result["reg_status_cd"])
        }
        result[:education_level] = educ_level_translator.translate(result["educ_level"])
        result[:california_residency] = cal_residency_translator.translate(result["cal_residency_flag"])
        result['affiliations'] ||= ""
        result[:roles] = {
          :student => result['affiliations'].include?("STUDENT-TYPE-"),
          :registered => result['affiliations'].include?("STUDENT-TYPE-REGISTERED"),
          :exStudent => result['affiliations'].include?("STUDENT-STATUS-EXPIRED"),
          :faculty => result['affiliations'].include?("EMPLOYEE-TYPE-ACADEMIC"),
          :staff => result['affiliations'].include?("EMPLOYEE-TYPE-STAFF"),
          :guest => result['affiliations'].include?("GUEST-TYPE-COLLABORATOR")
        }
        result
      else
        {}
      end
    end

    # TODO These translation classes should be relocated and implemented as functional modules.
    def reg_status_translator
      @reg_status_translator ||= Notifications::RegStatusTranslator.new
    end
    def educ_level_translator
      @educ_level_translator ||= Notifications::EducLevelTranslator.new
    end
    def cal_residency_translator
      @cal_residency_translator ||= Notifications::CalResidencyTranslator.new
    end

  end
end
