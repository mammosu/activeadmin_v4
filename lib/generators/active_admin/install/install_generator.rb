# frozen_string_literal: true
require "rails/generators/active_record"

module ActiveAdmin
  module Generators
    class InstallGenerator < ActiveRecord::Generators::Base
      desc "Installs Active Admin and generates the necessary migrations"
      argument :name, type: :string, default: "AdminUser"

      hook_for :users, default: "devise", desc: "Admin user generator to run. Skip with --skip-users"
      class_option :skip_comments, type: :boolean, default: false, desc: "Skip installation of comments"

      source_root File.expand_path("templates", __dir__)

      def copy_initializer
        @underscored_user_name = name.underscore.tr("/", "_")
        @use_authentication_method = options[:users].present?
        @skip_comments = options[:skip_comments]
        template "active_admin.rb.erb", "config/initializers/active_admin.rb"
      end

      def setup_directory
        empty_directory "app/admin"
        template "dashboard.rb", "app/admin/dashboard.rb"
        if options[:users].present?
          @user_class = name
          template "admin_users.rb.erb", "app/admin/#{name.underscore.pluralize}.rb"
        end
      end

      def setup_routes
        if options[:users] # Ensure Active Admin routes occur after Devise routes so that Devise has higher priority
          inject_into_file "config/routes.rb", "\n  ActiveAdmin.routes(self)", after: /devise_for .*, ActiveAdmin::Devise\.config/
        else
          route "ActiveAdmin.routes(self)"
        end
      end

      def create_assets
        generate "active_admin:assets"
      end

      def create_migrations
        unless options[:skip_comments]
          migration_template "migrations/create_active_admin_comments.rb.erb", "db/migrate/create_active_admin_comments.rb"
        end
      end

      def copy_stylesheets
        template "active_admin.css", "app/assets/stylesheets/active_admin.css"
        # テンプレートファイル内の特殊なワイルドカードを置換
        replace_gem_path_in_file("app/assets/stylesheets/active_admin.css")
      end

      private

      def replace_gem_path_in_file(file_path)
        return unless File.exist?(file_path)

        # ActiveAdminのgemパスを取得
        active_admin_gem_path = Gem.loaded_specs['activeadmin'].full_gem_path

        # ファイル内の特殊なワイルドカードを置換
        content = File.read(file_path)
        replaced_content = content.gsub('#ACTIVE_ADMIN_GEM#', active_admin_gem_path)
        File.write(file_path, replaced_content)
      end
    end
  end
end
