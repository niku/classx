require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require 'classx'

describe ClassX do
  describe '#has' do
    describe 'with coece' do
      describe 'when Array is value' do
        before do
          @class = Class.new
          @class.class_eval do
            include ClassX

            has :x, :isa => Integer, :coerce => [
              { proc {|val| val.respond_to? :to_i } => proc {|val| val.to_i } },
              { proc {|val| val.respond_to? :to_s } => proc {|val| val.to_s } },
            ]
          end
        end

        it 'attrubute :x should convert Str to Integer' do
          lambda { @class.new(:x => "10") }.should_not raise_error(Exception)
        end

        it 'attrubute :x should not convert  Object to Integer' do
          lambda { @class.new(:x => Object.new ) }.should raise_error(ClassX::InvalidAttrArgument)
        end
      end

      describe 'when Proc is value' do
        before do
          @class = Class.new
          @class.class_eval do
            include ClassX

            has :x, :isa => Integer, :coerce => proc {|val| ( val.respond_to?(:to_i) && val.to_i > 0 ) ? val.to_i : val }
          end
        end

        it 'attrubute :x should convert Str to Integer' do
          lambda { @class.new(:x => "10") }.should_not raise_error(Exception)
          @class.new(:x => "10").x.should == 10
        end

        it 'attrubute :x should not convert  Object to Integer' do
          lambda { @class.new(:x => Object.new ) }.should raise_error(ClassX::InvalidAttrArgument)
        end
      end

      describe 'when Proc is key' do
        before do
          @class = Class.new
          @class.class_eval do
            include ClassX

            has :x, :isa => Integer, :coerce => { proc {|val| val.respond_to? :to_i } => proc {|val| val.to_i } }
          end
        end

        it 'attrubute :x should convert Str to Integer' do
          lambda { @class.new(:x => "10") }.should_not raise_error(Exception)
        end

        it 'attrubute :x should not convert  Object to Integer' do
          lambda { @class.new(:x => Object.new ) }.should raise_error(ClassX::InvalidAttrArgument)
        end
      end

      describe 'when Symbol is key' do
        before do
          @class = Class.new
          @class.class_eval do
            include ClassX

            has :x, :isa => Integer, :coerce => { :to_i => proc {|val| val.to_i } }
          end
        end

        it 'attrubute :x should convert Str to Integer' do
          lambda { @class.new(:x => "10") }.should_not raise_error(Exception)
        end

        it 'attrubute :x should not convert  Object to Integer' do
          lambda { @class.new(:x => Object.new ) }.should raise_error(ClassX::InvalidAttrArgument)
        end
      end

      describe 'when Module or Class is key' do
        before do
          @class = Class.new
          @class.class_eval do
            include ClassX

            has :x, :isa => Integer, :coerce => { String => proc {|val| val.to_i } }, :writable => true
          end
        end

        it 'attrubute :x should convert Str to Integer' do
          lambda { @class.new(:x => "10") }.should_not raise_error(Exception)
        end

        it 'attrubute :x should not convert  Object to Integer' do
          lambda { @class.new(:x => Object.new ) }.should raise_error(ClassX::InvalidAttrArgument)
        end

        it 'rewrite attrubute :x should convert Str to Integer' do
          instance = @class.new(:x => "10")

          lambda { instance.x = "20" }.should_not raise_error(Exception)
          instance.x.should == 20
        end
      end
    end
  end
end
