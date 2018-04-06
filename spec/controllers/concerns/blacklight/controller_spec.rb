describe Blacklight::Controller do
  controller(ActionController::Base) do
    include Blacklight::Controller
    [:index, :create, :new, :show, :edit, :update, :destroy].each do |action_method|
      define_method(action_method) do
        flash[:notice] = "#{action_method} called"
        render plain: "#{action_method} called"
      end
    end
  end

  context "for all xhr requests" do
    [:index, :create, :new, :show, :edit, :update, :destroy].each do |action_method|
      %w{get post put delete}.each do |calltype|
        describe "#{calltype} :#{action_method}" do
          it "discards flash if blacklight_config.discard_flash_if_xhr is true" do
            allow(subject.blacklight_config).to receive(:discard_flash_if_xhr).and_return true
            send(calltype, action_method, xhr: true, params: { id: 'id' })
            #get action_method, xhr: true, params: { id: 'id' }
            expect(flash[:notice]).to be_present
            flash.sweep
            expect(flash[:notice]).not_to be_present
          end

          it "does not discard flash if blacklight_config.discard_flash_if_xhr is false" do
            allow(subject.blacklight_config).to receive(:discard_flash_if_xhr).and_return false
            send(calltype, action_method, xhr: true, params: { id: 'id' })
            #get action_method, xhr: true, params: { id: 'id' }
            expect(flash[:notice]).to be_present
            flash.sweep
            expect(flash[:notice]).to be_present
          end
        end
      end
    end
  end
end
