#
# Author:: AJ Christensen (<aj@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Resource::Group, "initialize" do
  before(:each) do
    @resource = Chef::Resource::Group.new("admin")
  end  

  it "should create a new Chef::Resource::Group" do
    @resource.should be_a_kind_of(Chef::Resource)
    @resource.should be_a_kind_of(Chef::Resource::Group)
  end

  it "should set the resource_name to :group" do
    @resource.resource_name.should eql(:group)
  end
  
  it "should set the group_name equal to the argument to initialize" do
    @resource.group_name.should eql("admin")
  end

  %w{members gid}.each do |attrib|
    it "should set #{attrib} to nil" do
      @resource.send(attrib).should eql(nil)
    end
  end
  
  it "should set action to :create" do
    @resource.action.should eql(:create)
  end
  
  %w{create remove modify manage}.each do |action|
    it "should allow action #{action}" do
      @resource.allowed_actions.detect { |a| a == action.to_sym }.should eql(action.to_sym)
    end
  end
end

describe Chef::Resource::Group, "group_name" do
  before(:each) do
    @resource = Chef::Resource::Group.new("admin")
  end

  it "should allow a string" do
    @resource.group_name "pirates"
    @resource.group_name.should eql("pirates")
  end

  it "should not allow a hash" do
    lambda { @resource.send(:group_name, { :aj => "is freakin awesome" }) }.should raise_error(ArgumentError)
  end
end

describe Chef::Resource::Group, "gid" do
  before(:each) do
    @resource = Chef::Resource::Group.new("admin")
  end

  it "should allow an integer" do
    @resource.gid 100
    @resource.gid.should eql(100)
  end

  it "should not allow a hash" do
    lambda { @resource.send(:gid, { :aj => "is freakin awesome" }) }.should raise_error(ArgumentError)
  end
end

describe Chef::Resource::Group, "members" do
  before(:each) do
    @resource = Chef::Resource::Group.new("admin")
  end

  it "should allow a string" do
    @resource.members "aj"
    @resource.members.should eql("aj")
  end

  it "should allow an array" do
    @resource.members [ "aj", "adam" ]
    @resource.members.should eql( ["aj", "adam"] )
  end

  it "should not allow a hash" do
    lambda { @resource.send(:members, { :aj => "is freakin awesome" }) }.should raise_error(ArgumentError)
  end
end