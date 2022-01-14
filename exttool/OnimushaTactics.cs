using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;

using BizHawk.Client.Common;

namespace Dev.YoshiRulz.MCTSHawkForDoug
{
	public sealed class OnimushaTactics : GameBase<OnimushaTactics.ActionType>
	{
		public enum ActionType : byte
		{
			OnimushaTactics = 0,
			Attack = 1,
			Done = 2,
			EndPhase = 3,
			Move = 4,
			SelectAttack = 5,
			SelectMove = 6,
			SelectUnit = 7,
		}

		private readonly ref struct UnitInfo
		{
			private readonly MainMemoryShim _mem;

			private readonly long _p;

			public readonly int unitNum;

			public readonly byte Flags
				=> _mem.readbyte(_p + 0xB8);

			public readonly byte ID
				=> _mem.readbyte(_p);

			public readonly bool IsAttackable
				=> ID > 0x17 && (Status & 0x02) is 0x02;

			public readonly bool IsControllable
				=> ID <= 0x10 // if unit is player-controlled
				   && (Flags & 0x01) is 0 // if unit has not finished turn
				   && (Status & 0x01) is 0x01; // if unit is alive

			public readonly byte Status
				=> _mem.readbyte(_p + 0x4A);

			public UnitInfo(MainMemoryShim mem, int unitNum, long addr)
			{
				_mem = mem;
				this.unitNum = unitNum;
				_p = addr;
			}
		}

		private const int UNIT_ADDR = 0x28DC;

		private const int UNIT_SIZE = 0xEC;

		private readonly Random rng = new();

		public override bool endFlag { get; set; } = false;

		public override string name => "Onimusha Tactics";

		private readonly ApiContainer APIs;

		private readonly MainMemoryShim mainmemory;

		public OnimushaTactics(ApiContainer apis)
		{
			APIs = apis;
			mainmemory = new(APIs.Memory);
		}

		[Conditional("false")]
		private void debugMsg(string s)
			=> Console.WriteLine(s);

		public override bool ended()
		{
#if true
			// player dead
			if (mainmemory.readbyte(0x2AE2) is 0)
			{
				debugMsg("endFlag: player dead");
//				APIs.EmuClient.Pause();
				return true;
			}

			// all enemies dead
			if (mainmemory.readbyte(0x38A0) is 0x4B or 0x2F or 0x01)
			{
				debugMsg("endFlag: stage won");
//				APIs.EmuClient.Pause();
				return true;
			}
#else
			var allDead = !Enumerable.Range(0, 0x10).Any(i => LazyUnitInfo(i).IsAttackable);
			if (allDead) return true;
#endif
			return false;
		}

		private UnitInfo LazyUnitInfo(int unitNum)
			=> new(mainmemory, unitNum: unitNum, addr: UNIT_ADDR + unitNum * UNIT_SIZE);

		public override IReadOnlyList<PossibleAction<ActionType>> getActs()
		{
			List<PossibleAction<ActionType>> acts = new();

			var SystemDataPtr = mainmemory.read_s16_le(0x2538);
			var GameDataPtr = mainmemory.read_s16_le(SystemDataPtr + 0xC);
//			var CursorX = mainmemory.readbyte(GameDataPtr + 0x62E);
//			var CursorY = mainmemory.readbyte(GameDataPtr + 0x630);

			var UnitXPosArr = GameDataPtr + 0xA8C;
			var UnitYPosArr = GameDataPtr + 0xA9C;

			var gameMode = mainmemory.readbyte(0x38A0);
			const byte SELECT_BATTLE_UNIT = 0x19;
			const byte UNIT_MENU = 0x1D;
			const byte SELECT_MOVE = 0x1A;
			const byte SELECT_ATTACK = 0x1E;

//			debugMsg($"{gameMode:X2}");
			switch (gameMode)
			{
				case SELECT_BATTLE_UNIT:
				{
//					debugMsg("  Current mode: Select Battle Unit");
					// Generate list of player units
					// Determine which ones are alive and can act
					// For each one, insert a selection act into acts
					for (var i = 0; i < 0x10; i++)
					{
						var curUnit = LazyUnitInfo(i);
						if (!curUnit.IsControllable) continue;
//						debugMsg($"Unit ID: {curUnit.ID}");
						var unitXpos = mainmemory.readbyte(UnitXPosArr + i);
						var unitYpos = mainmemory.readbyte(UnitYPosArr + i);
//						debugMsg($"Pos: {unitXpos}, {unitYpos}");
						acts.Add(new($"Select Unit @ {unitXpos}, {unitYpos}", ActionType.SelectUnit, (unitXpos, unitYpos)));
					}

//					acts.Add(new("End Phase", ActionType.EndPhase));
					break;
				}
				case UNIT_MENU:
				{
					var curUnit = /*LazyUnitInfo(mainmemory.readbyte(0x379C))*/LazyUnitInfo(2);
//					debugMsg(curUnit.unitNum.ToString());

//					debugMsg("  Current mode: Unit Menu");
//					debugMsg($"Unit flags: {curUnit.Flags}");
					if ((curUnit.Flags & 0x02) is 0)
					{
						if ((curUnit.Flags & 0x04) is 0) acts.Add(new("Select Move", ActionType.SelectMove));
						acts.Add(new("Select Attack", ActionType.SelectAttack));
					}
					else
					{
						acts.Add(new("Done", ActionType.Done));
					}
					break;
				}
				case SELECT_MOVE:
				{
					var curUnit = /*LazyUnitInfo(mainmemory.readbyte(0x379C))*/LazyUnitInfo(2);
					var unitX = mainmemory.readbyte(UnitXPosArr + curUnit.unitNum);
					var unitY = mainmemory.readbyte(UnitYPosArr + curUnit.unitNum);
//					debugMsg($"{unitX},{unitY}");
//					debugMsg("  Current mode: Select Move");
					// scan all tiles to see which are highlighted
					// insert act for each move

					for (byte yPos = 0; yPos < 0x10; yPos++)
					{
						var baseRow = 0x249C + yPos * 4;
						for (byte xPos = 0; xPos < 0x10; xPos++)
						{
//							debugMsg($"Checking {xPos}, {yPos}");
							var exactRow = baseRow + (xPos >> 3);
//							debugMsg($"exactRow: {exactRow:X4}");
							var baseVal = mainmemory.readbyte(exactRow);
//							debugMsg($"baseVal: {baseVal:X2}");
							var digit = xPos & 0b111;
//							debugMsg($"Digit: 2^{digit}");
							if (xPos == unitX && yPos == unitY)
							{
//								debugMsg("lol");
							}
							else if ((baseVal & (1 << digit)) is not 0)
							{
//								debugMsg($"Possible move detected: {xPos}, {yPos}");
								acts.Add(new($"Move to {xPos}, {yPos}", ActionType.Move, (xPos, yPos)));
							}
						}
					}
					break;
				}
				case SELECT_ATTACK:
				{
//					var curUnit = /*LazyUnitInfo(mainmemory.readbyte(0x379C))*/LazyUnitInfo(2);

//					debugMsg("Current mode: Select Attack");
					// scan all tiles to see which are highlighted and contain an attackable enemy unit
					// insert act for each attack

					for (byte yPos = 0; yPos < 0x10; yPos++)
					{
						var baseRow = 0x249C + yPos * 4;
//						debugMsg($"baseRow: {baseRow:X4}");
						for (byte xPos = 0; xPos < 0x10; xPos++)
						{
//							debugMsg($"Checking {xPos}, {yPos}");
							var exactRow = baseRow + (xPos >> 3);
//							debugMsg($"exactRow: {exactRow:X4}");
							var baseVal = mainmemory.readbyte(exactRow);
//							debugMsg($"baseVal: {baseVal:X4}");
							var digit = xPos & 0b111;
//							debugMsg($"Digit: 2^{digit}");
							if ((baseVal & (1 << digit)) is 0) continue;

							for (var i = 0; i < 0x10; i++)
							{
//								debugMsg($"{UnitXPosArr:X4}");
//								debugMsg($"{UnitYPosArr:X4}");
								if (xPos != mainmemory.readbyte(UnitXPosArr + i) || yPos != mainmemory.readbyte(UnitYPosArr + i)) continue;

								var curUnit = LazyUnitInfo(i);
//								debugMsg("data");
//								debugMsg(curUnit.ID.ToString());
//								debugMsg(curUnit.Status.ToString());
								if (curUnit.IsAttackable)
								{
//									debugMsg($"Possible attack detected: {xPos}, {yPos}");
									acts.Add(new($"Attack {xPos}, {yPos}", ActionType.Attack, (xPos, yPos)));
								}
							}
						}
					}
					break;
				}
			}

			if (acts.Count is 0)
			{
				mainmemory.writebyte(0x2AE2, 0);
				endFlag = true;
			}

			return acts;
		}

		public override void expand(Node<ActionType> p)
		{
//			debugMsg("  expand");
			var acts = getActs();
			p.children = acts.Count is 0
				? null
				: acts.ToDictionary(static v => v.id, v => new Node<ActionType>(v.id) { action = v, parent = p });
		}

		public override IEnumerable<bool> perform(PossibleAction<ActionType> act, PossibleAction<ActionType> act2 = default)
		{
			if (act.name is ActionType.OnimushaTactics) act = act2;

//			debugMsg("  perform");
//			debugMsg(act.ToString());

			var SpriteDataPtr = mainmemory.read_s16_le(0x2538);
			var DataPtr2 = mainmemory.read_s16_le(SpriteDataPtr + 0xC);
			var CursorX = mainmemory.readbyte(DataPtr2 + 0x62E);
			var CursorY = mainmemory.readbyte(DataPtr2 + 0x630);

//			var gameMode = mainmemory.readbyte(0x38A0);

			switch (act.name)
			{
				case ActionType.EndPhase:
				{
//					debugMsg("End Phase");
					APIs.Joypad.Set("Start", true);
					while (mainmemory.readbyte(0x38A0) is not 0x34) yield return true;

					APIs.Joypad.Set("Up", true);
					yield return true;
					APIs.Joypad.Set("A", true);
					yield return true;
					yield return true;
					APIs.Joypad.Set("Left", true);
					yield return true;
					APIs.Joypad.Set("A", true);

					while (mainmemory.readbyte(0x38A0) is not 0x50 && !endFlag)
					{
//						debugMsg("wait for 0x50");
						foreach (var b in waitFrameBreak()) yield return b;
						endFlag = false;
						if (endFlag)
						{
							debugMsg("endFlag 1");
							yield return false;
							yield break;
						}
					}
					while (mainmemory.readbyte(0x38A0) is not 0x19 && !endFlag)
					{
//						debugMsg("wait for 0x19");
						foreach (var b in waitFrameBreak()) yield return b;
						endFlag = false;
						if (endFlag)
						{
//							debugMsg("endFlag 2");
							yield return false;
							yield break;
						}
					}
					break;
				}
				case ActionType.SelectUnit:
				case ActionType.Move:
				case ActionType.Attack:
				{
					var (targetX, targetY) = act.Position!.Value;
//					debugMsg($"{targetX},{targetY}");
//					debugMsg($"{CursorX},{CursorY}");
					while (CursorX < targetX)
					{
						APIs.Joypad.Set("Left", true);
						yield return true;
						CursorX = mainmemory.readbyte(DataPtr2 + 0x62E);
					}

					while (CursorX > targetX)
					{
						APIs.Joypad.Set("Right", true);
						yield return true;
						CursorX = mainmemory.readbyte(DataPtr2 + 0x62E);
					}

					while (CursorY > targetY)
					{
						APIs.Joypad.Set("Down", true);
						yield return true;
						CursorY = mainmemory.readbyte(DataPtr2 + 0x630);
					}

					while (CursorY < targetY)
					{
						APIs.Joypad.Set("Up", true);
						yield return true;
						CursorY = mainmemory.readbyte(DataPtr2 + 0x630);
					}

					foreach (var b in waitFrames(10)) yield return b;
					APIs.Joypad.Set("A", true);
					while (mainmemory.readbyte(0x38A0) is not 0x1D && !endFlag)
					{
						foreach (var b in waitFrameBreak()) yield return b;
						endFlag = false;
						if (endFlag)
						{
							yield return false;
							yield break;
						}
					}
					foreach (var b in waitFrames(10)) yield return b;
					break;
				}
				case ActionType.SelectMove:
				{
					while (mainmemory.readbyte(0x281F) is not 0x00)
					{
						APIs.Joypad.Set("Down", true);
						yield return true;
					}
					APIs.Joypad.Set("A", true);
					while (mainmemory.readbyte(0x38A0) is not 0x1A) yield return true;
					break;
				}
				case ActionType.SelectAttack:
				{
					while (mainmemory.readbyte(0x281F) is not 0x01)
					{
						APIs.Joypad.Set("Down", true);
						yield return true;
					}
					APIs.Joypad.Set("A", true);
					while (mainmemory.readbyte(0x38A0) is not 0x1E && !endFlag)
					{
						foreach (var b in waitFrameBreak()) yield return b;
						endFlag = false;
						if (endFlag)
						{
							yield return false;
							yield break;
						}
					}
					break;
				}
				case ActionType.Done:
				{
					APIs.Joypad.Set("Up", true);
					yield return true;
					APIs.Joypad.Set("A", true);
					foreach (var b in waitFrames(10)) yield return b;

					// check if any units still to act
					var found = false;
					for (var i = 0; i < 0x10; i++) if (LazyUnitInfo(i).IsControllable)
					{
						found = true;
						break;
					}

					if (found) // If there are still more units
					{
						while (mainmemory.readbyte(0x38A0) is not 0x19) yield return true;
					}
					else // If there are no more units to act, proceed to next turn
					{
						while (mainmemory.readbyte(0x38A0) is not 0x50 && !endFlag)
						{
//							debugMsg("wait for 0x50");
							foreach (var b in waitFrameBreak()) yield return b;
							endFlag = false;
							if (endFlag)
							{
//								debugMsg("endFlag 1");
								yield return false;
								yield break;
							}
						}
						while (mainmemory.readbyte(0x38A0) is not 0x19 && !endFlag)
						{
//							debugMsg("wait for 0x19");
							foreach (var b in waitFrameBreak()) yield return b;
							endFlag = false;
							if (endFlag)
							{
//								debugMsg("endFlag 2");
								yield return false;
								yield break;
							}
						}
					}
					break;
				}
				default:
					debugMsg($"Perform ERROR: \"{act.name}\" not known");
					break;
			}

			yield return false;
		}

		public override IEnumerable<bool> rollout()
		{
			debugMsg("rollout");
			// Rollout logic:
			// Arbitrary action until end
			endFlag = false;
			while (!endFlag)
			{
				var acts = getActs();
				// random item
				if (acts.Count is 0)
				{
					endFlag = true;
					yield return false;
				}
				var a = acts[rng.Next(acts.Count)];
				debugMsg($"Performing random act: {a.id}");
				foreach (var b in perform(a))
				{
					if (!b) break;
					yield return b;
				}
			}
		}

		public override int rawscore
			=> 30000 - APIs.Emulation.FrameCount();

		public override int score
		{
			get
			{
				if (mainmemory.readbyte(0x38A0) is 0x4B) return rawscore;
				debugMsg(mainmemory.readbyte(0x38A0).ToString());
				return 0;
			}
		}
	}
}
