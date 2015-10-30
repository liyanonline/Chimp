module Simulators

push!(LOAD_PATH, ".")

using POMDPs

export
  Exp,
  Simulator,
  simulate!,
  reset!


abstract Simulator


type POMDPSimulator <: Simulator

  pomdp::POMDP
  
  b::Belief
  s::State
  o::Observation

  trans_dist::AbstractDistribution
  obs_dist::AbstractDistribution
  rng::AbstractRNG

  simover::Bool
  
  function POMDPSimulator(pomdp::POMDP; rng::AbstractRNG=MersenneTwister(rand(Uint32)))

    b = create_belief(pomdp)  # initial belief based on problem definition
    s = create_state(pomdp)  # initial state based on problem definition
    o = create_observation(pomdp)

    trans_dist = create_transition_distribution(pomdp)
    obs_dist = create_observation_distribution(pomdp)
    
    return new(pomdp, b, s, o, trans_dist, obs_dist, rng, false)

  end  # function POMDPSimulator

end  # type POMDPSimulator


type Exp

  b::Belief
  ia::ActionIndicator
  r::Reward
  bp::Belief
  nonterm::Bool  # whether sp is really terminal state

end  # type Exp


function simulate!(sim::POMDPSimulator, a::Action, aindex::Int64)
  
  r = reward(sim.pomdp, sim.s, a)

  transition!(sim.trans_dist, sim.pomdp, sim.s, a)
  rand!(sim.rng, sim.s, sim.trans_dist)
  
  observation!(sim.obs_dist, sim.pomdp, sim.s, a)
  rand!(sim.rng, sim.o, sim.obs_dist)

  b = deepcopy(sim.b)
  bp = create_belief(sim.pomdp)
  
  update_belief!(bp, sim.pomdp, sim.b, a, sim.o)
  sim.b = deepcopy(bp)

  isterm = isterminal(sim.pomdp, sim.s)
  if isterm
    reset!(sim)
  end  # if

  ia = zeros(Float64, n_actions(sim.pomdp))
  ia[aindex] = 1.0

  # must be memory-independent
  return Exp(b, ia, r, bp, !isterm)

end  # function simulate!


function reset!(sim::POMDPSimulator)

  sim.b = create_belief(sim.pomdp)
  sim.s = create_state(sim.pomdp)

end  # function reset!

end  # module Simulators