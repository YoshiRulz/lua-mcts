using System;
using System.Collections.Generic;
using System.Diagnostics;

using BizHawk.Client.Common;
using BizHawk.Client.EmuHawk;
using BizHawk.WinForms.Controls;

namespace Dev.YoshiRulz.MCTSHawkForDoug
{
	[ExternalTool("HelloWorld", Description = "An example of how to interact with EmuHawk")]
	public class MonteCarloToolForm : ToolFormBase, IExternalToolForm
	{
		/// <remarks>
		/// <see cref="ApiContainer"/> can be used as a shorthand for accessing the various APIs, more like the Lua syntax.
		/// </remarks>
		public ApiContainer? _apiContainer { get; set; }

		private ApiContainer APIs
			=> _apiContainer ?? throw new NullReferenceException();

		private readonly LabelEx _readout;

		private IEnumerator<bool>? _state = null;

		protected override string WindowTitleStatic
			=> "MonteCarloPE";

		private int BEST_SCORE = 0;

		public MonteCarloToolForm()
		{
			SuspendLayout();
			ClientSize = new(240, 240);
			Controls.Add(_readout = new());
			Name = nameof(MonteCarloToolForm);
			ResumeLayout();
		}

		[Conditional("false")]
		private void debugMsg(string s)
			=> Console.WriteLine(s);

		private void markTerminal<T>(Node<T> node)
			where T : Enum
		{
			debugMsg("markTerminal");
			debugMsg($"Marking as terminal: {node.name}");
			node.terminal = true;
			if (node.parent is null)
			{
				debugMsg("Root node detected: ending here");
				return;
			}
			node.parent.terminalChildren++;
			debugMsg($"Parent has {node.parent.terminalChildren} terminal children out of {node.parent.children!.Count} children total");
			if (node.parent.terminalChildren == node.parent.children.Count) markTerminal(node.parent);
		}

		/// <seealso cref="GameBase.DOCS_FAUXROUTINE"/>
		private IEnumerable<bool> MonteCarloTreeSearch<T>(GameBase<T> game, int n, Node<T> root, RefHack<Node<T>> topChild)
			where T : Enum
		{
			root.name = "root";

			for (var i = 0; i < n; i++)
			{
//				Console.WriteLine($"Iteration #{i}");
				var curNode = root;
				if (curNode.terminal) break;
				curNode.visits++;
//				APIs.MemorySaveState.LoadCoreStateFromMemory(curNode.state);

				while (curNode.state is not null)
				{
//					APIs.MemorySaveState.LoadCoreStateFromMemory(curNode.state);
					if (curNode.children is null)
					{
						APIs.MemorySaveState.LoadCoreStateFromMemory(curNode.state);
						game.expand(curNode);
						// skip analysis and designate this node as terminal if no children
						if (curNode.children is null)
						{
//							debugMsg("No children. skipping...");
							game.endFlag = true;
							break;
						}
					}
					curNode = selection(curNode);
//					debugMsg($"Selected action: {curNode.name}");
					curNode.visits++;
				}

				if (!game.endFlag)
				{
					APIs.MemorySaveState.LoadCoreStateFromMemory(curNode.parent!.state);
					foreach (var b in game.perform(curNode.action))
					{
						if (!b) break;
						yield return b;
					}
					curNode.state = APIs.MemorySaveState.SaveCoreStateToMemory();
					if (game.rawscore < BEST_SCORE)
					{
//						print("skipping (too deep)");
						game.endFlag = true;
					}
				}

				if (game.endFlag)
				{
					markTerminal(curNode);
				}
				else
				{
					foreach (var b in game.rollout())
					{
						if (!b) break;
						yield return b;
					}
				}

				var result = game.score;
				debugMsg(result.ToString());
				if (result > BEST_SCORE)
				{
					BEST_SCORE = result;
					Console.WriteLine($"New best score: {BEST_SCORE}");
//					APIs.EmuClient.Pause();
				}
//				debugMsg($"Score: {result}");
				game.endFlag = false;

				while (curNode is not null)
				{
					curNode.value = Math.Max(curNode.value, result);
//					curNode.value += result;
					curNode = curNode.parent;
				}

			}

			var topScore = -999;
			foreach (var child in root.children!.Values)
			{
//				var temp = child.value / child.visits;
				var temp = child.value;
				if (temp > topScore)
				{
					topChild.Val = child;
					topScore = temp;
				}
			}

			yield return false;
		}

		public override void Restart()
		{
			BEST_SCORE = 0;
			debugMsg("Starting simulation");
			_readout.Text = "Starting simulation";
			_state = simulate(new OnimushaTactics(APIs), 2500, 2500).GetEnumerator();
		}

		private Node<T> selection<T>(Node<T> node)
			where T : Enum
		{
			debugMsg("selection");
			Node<T>? topChild = null;
			var topScore = -999;

			var c = Math.Sqrt(2);
			var k = node.value / 2;
//			var k = 0;

			foreach (var child in node.children!.Values)
			{
				if (child.terminal)
				{
					debugMsg($"skipping terminal child: {child.name}");
				}
				else
				{
					int score;
					if (child.visits > 0)
					{
						var temp = child.value;
//						var temp = child.value / child.visits;
						score = (int) (temp + c * Math.Sqrt(2.0 * Math.Log(node.visits) / child.visits));
					}
					else
					{
						score = (int) (k + c * Math.Sqrt(2.0 * Math.Log(node.visits) / (node.cn + 1)));
					}
					if (score > topScore)
					{
						topChild = child;
						topScore = score;
					}
				}
			}

			if (topChild is null)
			{
				debugMsg("selection ERROR: node has no children");
				throw new NullReferenceException();
			}

			if (topChild.visits == 0) node.cn++;

			debugMsg($"Selected action: {topChild.name}");
			return topChild;
		}

		/// <seealso cref="GameBase.DOCS_FAUXROUTINE"/>
		private IEnumerable<bool> simulate<T>(GameBase<T> game, int N, int n)
			where T : Enum
		{
			Node<T>? root = new(null) { state = APIs.MemorySaveState.SaveCoreStateToMemory() };
			for (var i = 1; i < N; i++)
			{
				Console.WriteLine($"Starting move {i}");
				RefHack<Node<T>> topChild = new();
				foreach (var b in MonteCarloTreeSearch(game, (int) (n / Math.Pow(1.01, i)), root, topChild))
				{
					if (!b) break;
					yield return b;
				}
				root = topChild.Val;
				if (root is null) break;
				APIs.MemorySaveState.LoadCoreStateFromMemory(root.state);
				root.parent = null;
				Console.WriteLine($"Selected move: {root.name} (score = {root.value})");
//				APIs.EmuClient.Pause();
			}
			_readout.Text = "Finished";
			yield return false;
		}

		public override void UpdateValues(ToolFormUpdateType type)
		{
			if (_state is null || type is not (ToolFormUpdateType.PreFrame or ToolFormUpdateType.FastPreFrame)) return;
			if (_state.Current is false)
			{
				_state.Dispose();
				_state = null;
			}
		}
	}
}
