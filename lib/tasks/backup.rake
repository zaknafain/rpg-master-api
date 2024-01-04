# frozen_string_literal: true

namespace :db do
  desc 'Restores the admin user'
  task restore_admin: :environment do
    email    = ENV.fetch('ADMIN_EMAIL', nil)
    password = ENV.fetch('ADMIN_PASSWORD', nil)

    unless email && password
      puts '!!! ADMIN_EMAIL and ADMIN_PASSWORD need to be set'

      next
    end

    admin = User.find_or_initialize_by(email:).tap do |user|
      user.password = user.password_confirmation = password
    end
    admin.save!
  end
end
