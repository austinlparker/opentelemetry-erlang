%%%------------------------------------------------------------------------
%% Copyright 2019, OpenTelemetry Authors
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%% http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%
%% @doc
%% @end
%%%-------------------------------------------------------------------------
-module(opentelemetry_sup).

-behaviour(supervisor).

-export([start_link/1]).

-export([init/1]).

-define(SERVER, ?MODULE).

start_link(Opts) ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, [Opts]).

init([Opts]) ->
    SupFlags = #{strategy => one_for_one,
                 intensity => 1,
                 period => 5},

    %% configuration server
    TracerServer = #{id => otel_tracer_server,
                     start => {otel_tracer_provider, start_link, [otel_tracer_server, Opts]},
                     restart => permanent,
                     shutdown => 5000,
                     type => worker,
                     modules => [otel_tracer_provider, otel_tracer_server]},

    %%
    MetricSup = #{id => otel_metric_sup,
                  start => {otel_metric_sup, start_link, [Opts]},
                  restart => permanent,
                  shutdown => 5000,
                  type => supervisor,
                  modules => [otel_metric_sup]},

    Processors = proplists:get_value(processors, Opts, []),
    BatchProcessorOpts = proplists:get_value(otel_batch_processor, Processors, #{}),
    BatchProcessor = #{id => otel_batch_processor,
                       start => {otel_batch_processor, start_link, [BatchProcessorOpts]},
                       restart => permanent,
                       shutdown => 5000,
                       type => worker,
                       modules => [otel_batch_processor]},

    SpanSup = #{id => otel_span_sup,
                start => {otel_span_sup, start_link, [Opts]},
                type => supervisor,
                restart => permanent,
                shutdown => 5000,
                modules => [otel_span_sup]},

    %% `TracerServer' *must* start before the `BatchProcessor'
    %% `BatchProcessor' relies on getting the `Resource' from
    %% the `TracerServer' process
    ChildSpecs = [MetricSup, TracerServer, BatchProcessor, SpanSup],

    {ok, {SupFlags, ChildSpecs}}.
