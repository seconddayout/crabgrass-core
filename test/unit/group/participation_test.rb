require 'test_helper'

class Group::ParticipationTest < ActiveSupport::TestCase
  def test_name_change
    group = groups(:rainbow)

    pages = group.pages.select { |page| page.owner_name == group.name }

    group.name = 'colors'
    group.save!

    assert !pages.empty?
    pages.each do |page|
      page.reload
      assert_equal group.name, page.owner_name
    end
  end

  def test_associations
    assert check_associations(Group::Participation)
  end
end
