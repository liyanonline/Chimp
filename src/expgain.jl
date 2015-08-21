# actions must be a discrete set, since we're dealing with dnn
typealias Actions Vector{Action}


# interface between simulator and replay dataset
type Expgain

  deepnet::DeepNet
  sim::Simulator
  dataset::ReplayDataset
  
  actions::Actions
  prevBelief::Belief

end  # type Expgain


function select_action(expgain::Expgain, belief::Belief, epsilon::Float64)

  if rand() < epsilon
    return expgain.actions[rand(1:length(expgain.actions))]
  else
    return expgain.actions[select_action(expgain.deepnet, belief)]
  end  # if

end  # function select_action


function get_epsilon(iter::Int64)

  if iter > EpsilonCount
    return EpsilonMin
  else
    return EpsilonFinal + (EpsilonStart - EpsilonFinal) * 
           max(EpsilonCount - iter, 0) / EpsilonCount
  end  # if

end  # function get_epsilon


# mutates simulator in expgain to get new experience
function generate_experience!(expgain::ExpGain, iter::Int64)

  a = select_action(expgain, get_epsilon(iter))
  return simulate!(expgain.sim, a)

end  # function generate_experience!