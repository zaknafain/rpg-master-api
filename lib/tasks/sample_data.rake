namespace :db do
  desc 'Fill database with sample data'
  task populate: :environment do
    make_minimalist
    make_exorbitant
    make_users
    make_campaigns
    assign_players
    make_hierarchy_elements
    assign_element_readers
    # make_content_texts
  end
end

def make_minimalist
  puts 'Creating minimalist user'
  user = create_user!(name: 'M', email: 'm@i.n', password: 'password', admin: true)
  create_campaign!(name: 'C', description: 'Text', is_public: false, short_description: nil, user_id: user.id)
end

def make_exorbitant
  puts 'Creating exorbitant user'
  user = create_user!(name: 'Maximilian Mustermann', email: 'maximilian.mustermann@exorbitant.co.uk')
  20.times do
    create_campaign!(name: [FFaker::Movie.title, FFaker::Movie.title, FFaker::Movie.title].join(' aka. '),
                     description: random_markdown(100),
                     is_public: true,
                     user_id: user.id)
  end
end

def make_users
  puts 'Creating users'
  30.times do |n|
    create_user!(admin: (n % 10).zero?)
  end
end

def make_campaigns
  puts 'Creating campaigns'
  40.times do
    create_campaign!
  end
end

def assign_players
  puts 'Assign players'
  Campaign.all.each do |campaign|
    players = User.where.not(id: campaign.user_id).sample((0..5).to_a.sample)
    campaign.players = players
    campaign.save!
  end
end

def make_hierarchy_elements
  puts 'Create hierarchy elements'
  Campaign.all.each do |campaign|
    (0..10).to_a.sample.times do |i|
      element = create_hierarchy_element!(campaign)
      (0..5).to_a.sample.times do |j|
        create_hierarchy_element!(element)
      end
    end
  end
end

def assign_element_readers
  puts 'Assign hierarchy element readers'
  HierarchyElement.where(visibility: :for_some).each do |element|
    players = element.top_hierarchable.players
    next if players.empty?

    players.sample((1..players.length).to_a.sample).each do |player|
      element.hierarchy_elements_users.create!(user_id: player.id)
    end
  end
end

# def make_content_texts
#   HierarchyElement.all.each do |element|
#     text_count = (0..10).to_a.sample
#     text_count.times do |i|
#       puts "Creating ContentText #{i} for HierarchyElement ##{element.id}"
#       create_content_text(element, i)
#     end
#   end
# end

def create_user!(user_params = {})
  params = {
    name: FFaker::Internet.user_name,
    email: FFaker::Internet.email,
    password: FFaker::Internet.password,
    locale: I18n.available_locales.sample,
    admin: false
  }.merge(user_params)

  user = User.find_or_initialize_by(email: params[:email])
  user.assign_attributes(params.merge(password_confirmation: params[:password]))
  user.save!

  user
end

def create_campaign!(campaign_params = {})
  params = {
    name: FFaker::Movie.title,
    short_description: random_text(10),
    description: random_markdown(30),
    is_public: [true, false].sample,
    user_id: random_user&.id
  }.merge(campaign_params)

  campaign = Campaign.find_or_initialize_by(name: params[:name])
  campaign.assign_attributes(params)
  campaign.save!

  campaign
end

def create_hierarchy_element!(hierarchable, element_params = {})
  params = {
    name: FFaker::Music.genre,
    visibility: %i[for_everyone for_all_players for_some author_only].sample,
    description: random_text(3)
  }.merge(element_params)

  element = hierarchable.hierarchy_elements.find_or_initialize_by(name: params[:name])
  element.assign_attributes(params)
  element.save!

  element
end

# def create_content_text(element, order)
#   visibility = %i[for_everyone for_all_players author_only].sample

#   element.content_texts.create(content: random_markdown,
#                                order: order,
#                                visibility: visibility)
# end

def random_user
  User.where.not(email: ['maximilian.mustermann@exorbitant.co.uk', 'm@i.n']).sample
end

def random_text(max = nil)
  count = (1..(max || 5)).to_a.sample

  FFaker::Lorem.sentences(count).join(' ')
end

def random_markdown(max = nil)
  count = (1..(max || 10)).to_a.sample
  markdown = []
  count.times do
    markdown << send(%w[markdown_headline
                        markdown_paragraph
                        markdown_quote
                        markdown_words
                        markdown_list].sample)
  end

  markdown.join("\n\n")
end

def markdown_headline(type = nil)
  type ||= (1..6).to_a.sample

  "#{'#' * type} #{FFaker::CheesyLingo.title}"
end

def markdown_paragraph
  FFaker::BaconIpsum.paragraph
end

def markdown_words(type = nil)
  type ||= %w[* ** _ __ == ~~].sample

  [FFaker::BaconIpsum.word,
   FFaker::BaconIpsum.word,
   "#{type}#{FFaker::BaconIpsum.word}#{type}",
   FFaker::BaconIpsum.word].join(' ')
end

def markdown_quote
  lines = (1..10).to_a.sample
  quote = []
  lines.times do
    quote << "> #{FFaker::BaconIpsum.phrase}"
  end

  quote.join("\n")
end

def markdown_list
  type = %w[+ -].sample
  count = (1..10).to_a.sample
  list = []
  count.times do
    list << "#{type} #{FFaker::BaconIpsum.sentence}"
  end

  list.join("\n")
end
