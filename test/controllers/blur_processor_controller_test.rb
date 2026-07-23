require "test_helper"

class BlurProcessorControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get blur_processor_index_url
    assert_response :success
  end

  test "should get upload" do
    get blur_processor_upload_url
    assert_response :success
  end

  test "should get result" do
    get blur_processor_result_url
    assert_response :success
  end
end
