module TestOfflineRL
using AutoOfflineRL
using Test
using DataFrames
using PythonCall
using Parquet
const PYC=PythonCall

@testset "Load Agents with Default Params" begin
  for agentid in keys(AutoOfflineRL.OfflineRLs.rl_dict)
    @info "loading $agentid default params"
    rlagent = DiscreteRLOffline(agentid) 
    @test typeof(rlagent) <: AutoOfflineRL.Learner
  end
end


@testset "Load Agents with Param Args" begin
  println()
  for agentid in keys(AutoOfflineRL.OfflineRLs.rl_dict)
    @info "loading $agentid with customized params"
    rlagent = DiscreteRLOffline(agentid,
          Dict(:name=>agentid,
               :iterations=>10000,
               :epochs=>100)
         ) 
    @test typeof(rlagent) <: AutoOfflineRL.Learner
  end
end

@testset "Test Exceptions" begin
  @test_throws ErrorException DiscreteRLOffline("dummy")
end

@testset "Test Agent fit!/transform Runs" begin
  println()
  path = pkgdir(AutoOfflineRL)
  dataset = "$path/data/smalldata.parquet"
  df = Parquet.read_parquet(dataset) |> DataFrame |> dropmissing
  df_input = df[:, ["day", "hour", "minute", "dow", "metric1", "metric2", "metric3", "metric4"]]
  reward = df[:,["reward"]] |> deepcopy |> DataFrame
  action = df[:,["action"]] |> deepcopy |> DataFrame
  action_reward = DataFrame[action, reward]
  for agentid in keys(AutoOfflineRL.OfflineRLs.rl_dict)
    @info "training $agentid"
    agent = DiscreteRLOffline(agentid; save_model=false,runtime_args=Dict(:n_epochs=>1,:verbose=>false, :show_progress=>true))
    o_header = agent.model[:o_header]
    fit!(agent,df_input,action_reward) 
    @test agent.model[:rlobjtrained] !== PYC.PyNULL
    @info "transform $agentid"
    adf = df_input[1:2,:]
    if agentid != "DiscreteBC"
       res = AutoOfflineRL.transform!(agent,adf)
       @test typeof(res[1]) .== NamedTuple{(:obs,:action, :value), Tuple{Vector{Float64},Vector{Float64}, Vector{Float64}}}
    end
  end
end


end
