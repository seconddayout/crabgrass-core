class PagePolicy < ApplicationPolicy
  # public pages do not require a login in the controller
  # but the permission will still be checked here.
  # So we need to make sure users who do not have explicit
  # access the page can still see it if it's public.
  def show?
    record.public? || user.may?(:view, record)
  end

  def create?
    return group_allows_adding_page? if group
    admin?
  end

  def update?
    user.may?(:edit, record)
  end

  def admin?
    user.may?(:admin, record)
  end

  alias_method :print?, :show?
  alias_method :new?, :logged_in?
  alias_method :destroy?, :admin?

  protected

  def group
    record.group
  end

  def group_allows_adding_page?
    user.may?(:edit, group) or group.access?(public: :view)
  end

end
