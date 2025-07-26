from util import manhattanDistance
from game import Directions
import random, util

from game import Agent

class ReflexAgent(Agent):
  def __init__(self):
    self.lastPositions = []
    self.dc = None

  def getAction(self, gameState):
    legalMoves = gameState.getLegalActions()

    scores = [self.evaluationFunction(gameState, action) for action in legalMoves]
    bestScore = max(scores)
    bestIndices = [index for index in range(len(scores)) if scores[index] == bestScore]
    chosenIndex = random.choice(bestIndices)  
    return legalMoves[chosenIndex]

  def evaluationFunction(self, currentGameState, action): 
    successorGameState = currentGameState.generatePacmanSuccessor(action)
    newPos = successorGameState.getPacmanPosition()
    oldFood = currentGameState.getFood()
    newGhostStates = successorGameState.getGhostStates()
    newScaredTimes = [ghostState.scaredTimer for ghostState in newGhostStates]

    return successorGameState.getScore()


def scoreEvaluationFunction(currentGameState):
  return currentGameState.getScore()

class MultiAgentSearchAgent(Agent):
  def __init__(self, evalFn = 'scoreEvaluationFunction', depth = '2'):
    self.index = 0 
    self.evaluationFunction = util.lookup(evalFn, globals())
    self.depth = int(depth)


class MinimaxAgent(MultiAgentSearchAgent):
    def getAction(self, gameState):
        def minimax(agentIndex, depth, state):
            if state.isWin() or state.isLose() or depth == self.depth:
                return self.evaluationFunction(state)

            numAgents = state.getNumAgents()
            nextAgent = (agentIndex + 1) % numAgents
            nextDepth = depth + 1 if nextAgent == 0 else depth

            legalActions = state.getLegalActions(agentIndex)
            if not legalActions:
                return self.evaluationFunction(state)

            successors = [state.generateSuccessor(agentIndex, action) for action in legalActions]
            values = [minimax(nextAgent, nextDepth, succ) for succ in successors]

            if agentIndex == 0: 
                return max(values)
            else:
                return min(values)

        legalActions = gameState.getLegalActions(0)
        bestAction = None
        bestValue = float("-inf")

        for action in legalActions:
            successor = gameState.generateSuccessor(0, action)
            value = minimax(1, 0, successor)
            if value > bestValue:
                bestValue = value
                bestAction = action

        return bestAction

class AlphaBetaAgent(MultiAgentSearchAgent):
    def getAction(self, gameState):

        def alphaBeta(agentIndex, depth, state, alpha, beta):
            if state.isWin() or state.isLose() or depth == self.depth:
                return self.evaluationFunction(state)
            numAgents = state.getNumAgents()
            nextAgent = (agentIndex + 1) % numAgents
            nextDepth = depth + 1 if nextAgent == 0 else depth

            legalActions = state.getLegalActions(agentIndex)
            if not legalActions:
                return self.evaluationFunction(state)
            if agentIndex == 0:
                value = float("-inf")
                for action in legalActions:
                    successor = state.generateSuccessor(agentIndex, action)
                    value = max(value, alphaBeta(nextAgent, nextDepth, successor, alpha, beta))
                    if value > beta:
                        return value 
                    alpha = max(alpha, value)
                return value
            else: 
                value = float("inf")
                for action in legalActions:
                    successor = state.generateSuccessor(agentIndex, action)
                    value = min(value, alphaBeta(nextAgent, nextDepth, successor, alpha, beta))
                    if value < alpha:
                        return value  
                    beta = min(beta, value)
                return value

        alpha = float("-inf")
        beta = float("inf")
        bestAction = None
        bestValue = float("-inf")

        for action in gameState.getLegalActions(0):
            successor = gameState.generateSuccessor(0, action)
            value = alphaBeta(1, 0, successor, alpha, beta)
            if value > bestValue:
                bestValue = value
                bestAction = action
            alpha = max(alpha, bestValue)

        return bestAction

class ExpectimaxAgent(MultiAgentSearchAgent):
    def getAction(self, gameState):
        def expectimax(agentIndex, depth, state):
            if state.isWin() or state.isLose() or depth == self.depth:
                return self.evaluationFunction(state)

            numAgents = state.getNumAgents()
            nextAgent = (agentIndex + 1) % numAgents
            nextDepth = depth + 1 if nextAgent == 0 else depth

            legalActions = state.getLegalActions(agentIndex)
            if not legalActions:
                return self.evaluationFunction(state)

            successors = [state.generateSuccessor(agentIndex, action) for action in legalActions]

            if agentIndex == 0:
                values = [expectimax(nextAgent, nextDepth, succ) for succ in successors]
                return max(values)
            else:
                values = [expectimax(nextAgent, nextDepth, succ) for succ in successors]
                return sum(values) / len(values)  

        legalActions = gameState.getLegalActions(0)
        bestAction = None
        bestValue = float("-inf")

        for action in legalActions:
            successor = gameState.generateSuccessor(0, action)
            value = expectimax(1, 0, successor)
            if value > bestValue:
                bestValue = value
                bestAction = action

        return bestAction



def betterEvaluationFunction(currentGameState):
  raise Exception("Not implemented yet")

# Abbreviation
better = betterEvaluationFunction
