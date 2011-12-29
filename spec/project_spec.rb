require "spec_helper"

describe Tasks do
  test "detect_indent" do
    pending "no clue how to test this"
  end

	describe Tasks::Project do
    test ".parse" do
      assert_equal true, Tasks::Project.parse([], [], 2)
    end
  end
end
