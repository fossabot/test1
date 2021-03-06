# Encoding: utf-8
# Cloud Foundry Java Buildpack
# Copyright 2015 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'
require 'component_helper'
require 'java_buildpack/framework/dyna_trace_agent'

describe JavaBuildpack::Framework::DynaTraceAgent do
  include_context 'component_helper'

  it 'does not detect without dynatrace-n/a service' do
    expect(component.detect).to be_nil
  end

  context do

    before do
      allow(services).to receive(:one_service?).with(/dynatrace/, 'server').and_return(true)
      allow(services).to receive(:find_service).and_return('credentials' => { 'server' => 'test-host-name' })
    end

    it 'detects with dynatrace-n/a service' do
      expect(component.detect).to eq("dyna-trace-agent=#{version}")
    end

    it 'expands DynaTrace agent zip',
       cache_fixture: 'stub-dyna-trace-agent.jar' do

      component.compile
      expect(sandbox + 'agent/lib64/libdtagent.so').to exist
    end

    it 'updates JAVA_OPTS' do
      component.release
      expect(java_opts).to include(
        '-agentpath:$PWD/.java-buildpack/dyna_trace_agent/agent/lib64/'\
        'libdtagent.so=name=test-application-name_Monitoring,server=test-host-name')
    end
  end

  context do
    before do
      allow(services).to receive(:one_service?).with(/dynatrace/, 'server').and_return(true)
      allow(services).to receive(:find_service).and_return('credentials' => { 'server' => 'test-host-name',
                                                                              'profile' => 'test-profile' })
    end

    it 'updates JAVA_OPTS with custom profile' do
      component.release
      expect(java_opts).to include(
        '-agentpath:$PWD/.java-buildpack/dyna_trace_agent/agent/lib64/'\
        'libdtagent.so=name=test-application-name_test-profile,server=test-host-name')
    end

  end
end
