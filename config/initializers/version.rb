Rails.application.config.app_version = ENV["APP_VERSION"].presence || "dev"
Rails.application.config.git_revision = ENV["GIT_REVISION"].presence
