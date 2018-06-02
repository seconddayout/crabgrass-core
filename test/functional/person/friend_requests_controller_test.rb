require 'test_helper'

class Person::FriendRequestsControllerTest < ActionController::TestCase
  def test_new_contact_request_notifies_recipient
    users(:yellow).grant_access! public: :request_contact
    requesting = users(:red)
    recipient  = users(:yellow)
    login_as requesting

    assert_difference 'Notice::RequestNotice.count', 1 do
      xhr :post, :create, person_id: recipient.login
    end

    notice = Notice::RequestNotice.last
    assert_equal recipient.id, notice.user_id
    assert_equal 'request_to_friend', notice.data[:title]
  end

  def test_checking_permissions
    requesting = users(:red)
    recipient  = users(:yellow)
    login_as requesting

    assert_raises Pundit::NotAuthorizedError do
      xhr :post, :create, person_id: recipient.login
    end
  end
end
