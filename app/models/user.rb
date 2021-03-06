class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable , :validatable,
         :omniauthable, :omniauth_providers => [:facebook]

  has_many :friend_requests, class_name: "FriendRequest",
    foreign_key: :user_id

  has_many :received_requests, class_name: "FriendRequest",
    foreign_key: :friend_id

  has_many :pending_friends, through: :friend_requests,
    source: :friend, dependent: :destroy

  has_many :pending_acceptances, through: :received_requests,
    source: :user, dependent: :destroy

  has_many :active_friendships,class_name: "Friendship",
  foreign_key: :user_id, dependent: :destroy

  has_many :passive_friendships,class_name: "Friendship",
  foreign_key: :friend_id, dependent: :destroy

  has_many :added_friends, through: :active_friendships,
  dependent: :destroy,source: :friend

  has_many :added_by_friends, through: :passive_friendships,
  dependent: :destroy,source: :user

  has_many :posts, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :comments, dependent: :destroy

  validates :name, presence: true

  mount_uploader :image, PictureUploader
  mount_uploader :wallpaper, PictureUploader

  validate :image_size
  validate :wallpaper_size

  scope :suggested_friends,
    -> { where('id NOT IN (SELECT DISTINCT(friend_id) FROM friendships)') }

  def friends
    added_friends + added_by_friends
  end

  def requests
    friend_requests + received_requests
  end

  def users_in_request
    pending_friends + pending_acceptances
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] &&  session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0,20]
      user.name = auth.info.name
      user.image = URI.parse(auth.info.image)
    end
  end

  def first_name
    self.name.split.first
  end

  def feed
    # Scaping id value with the question mark to avoid SQL injection.
    # Here id is just an integer but it is better to use always this
    # approach
    Post.where("user_id = ?", id)
  end


  def image_size
    if image.size > 5.megabytes
      errors.add(:image, "should be less than 5MB")
    end
  end

  def wallpaper_size
    if wallpaper.size > 5.megabytes
      errors.add(:wallpaper, "should be less than 5MB")
    end
  end
end
