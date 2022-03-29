version 4.7

class YetAnotherShieldCore : ShieldCore
{
	Default
	{
		Inventory.Icon "USGIA0";
	}

	States
	{
		Spawn:
			USGI ABCD Random(1, 10);
			loop;
	}
}

class YetAnotherSpentShield : SpentShield
{
	States
	{
		Spawn:
			USGI A 0;
			goto Spawn2;
	}
}

class YetAnotherBrownSphere : BlueSphere replaces BrownSphere
{
	override void A_HDUPKGive()
	{
		if (!PickTarget || bNoInteraction) return;

		bool giveShield = CVar.GetCVar("yasca_browngiveshield").GetBool();
		PickTarget.A_GiveInventory((giveShield)? "YetAnotherShieldCore" : "SpiritualArmour", 1);

		if (giveShield) YASCAHandler.ForceUseYASC(HDPlayerPawn(PickTarget));

		Super.A_HDUPKGive();
	}

	States
	{
		Spawn:
			MEGA ABCD Random(2, 7) Bright;
			loop;
	}
}


class YASCAHandler : EventHandler
{
	static void ForceUseYASC(HDPlayerPawn hdp)
	{
		let yasc = hdp.FindInventory("YetAnotherShieldCore");
		if (
			yasc &&
			!hdp.CountInv("HDMagicShield") &&
			hdp.Player
		)
		{
			int btBak = hdp.Player.Cmd.Buttons;
			hdp.Player.Cmd.Buttons &=~ BT_USE;
			hdp.UseInventory(yasc);
			hdp.Player.Cmd.Buttons = btBak;
		}
	}

	override void RenderOverlay(RenderEvent e)
	{
		let hdp = HDPlayerPawn(Players[ConsolePlayer].Mo);
		if (!hdp) return;

		Font fnt = "INDEXFONT_DOOM";
		HUDFont mIndexFont = HUDFont.Create(fnt, fnt.GetCharWidth("0"), Mono_CellLeft);

		int mCount = hdp.CountInv("HDMagicShield");
		string counter =
			(!yasca_showshield)? "" :
			(mCount > 0)? String.Format("%d", mCount) :
			(yasca_alwaysshowshield)? "0" : "";

		StatusBar.DrawString(
			mIndexFont,
			counter,
			(8, -5),
			StatusBar.DI_TEXT_ALIGN_RIGHT | StatusBar.DI_SCREEN_CENTER_BOTTOM,
			Font.CR_Green,
			scale:(0.75, 0.75)
		);

		mCount = 0;
		class a;
		string s = "SpiritualArmour";

		a = s;
		if (a) mCount += hdp.CountInv(s);

		s = "SpiritualShield";
		a = s;
		if (a) mCount += hdp.CountInv(s);

		counter =
			(!yasca_showspirit)? "" :
			(mCount > 0)? String.Format("%d", mCount) :
			(yasca_alwaysshowspirit)? "0" : "";

		StatusBar.DrawString(
			mIndexFont,
			counter,
			(12, -5),
			StatusBar.DI_TEXT_ALIGN_RIGHT | StatusBar.DI_SCREEN_CENTER_BOTTOM,
			Font.CR_Gold,
			scale:(0.75, 0.75)
		);
	}

	override void WorldThingSpawned(WorldEvent e)
	{
		let T = Inventory(e.Thing);
		int mode = CVar.GetCVar("yasca_mode").GetInt();
		int giveOnlySpirit = CVar.GetCVar("yasca_giveonlyspirit").GetBool();

		if (!T) return;

		YetAnotherShieldCore yasc;
		string scName = "YetAnotherShieldCore";
		string spName = "SpiritualArmour";
		let hdp = HDPlayerPawn(T.Owner);

		switch (T.GetClassName())
		{
			// I give up on trying to make "Only Shield Cores" work.
			// Spiritual Armour is just a normal inventory item, so it doesn't spawn a new item everytime it increments its amount
			case 'SpiritualShield':
			case 'SpiritualArmour':
				if (hdp) break;
				else if (mode == 0) yasc = YetAnotherShieldCore(Actor.Spawn("YetAnotherShieldCore", T.Pos));
				else break;

				T.Destroy();
				break;

			case 'ShieldGenerator':
			case 'ShieldCore':
				if (hdp)
				{
					if (!giveOnlySpirit)
					{
						if (Wads.CheckNumForName("id", 0) == -1) break; // DO NOT give YASC when in Freedoom, as the brownsphere should automatically do everything on its own
						hdp.GiveInventory("YetAnotherShieldCore", 1);
						yasc = YetAnotherShieldCore(hdp.FindInventory("YetAnotherShieldCore"));

						// Since you got given this... that means it should be auto used, right?
						ForceUseYASC(hdp);
					}
					else hdp.GiveInventory(spName, 1);
				}
				else if (mode == 1) Actor.Spawn(spName, T.Pos);
				else yasc = YetAnotherShieldCore(Actor.Spawn("YetAnotherShieldCore", T.Pos));

				// Copy over contents
				if (yasc)
				{
					let sc = HDMagAmmo(T);
					yasc.Mags.Clear();
					yasc.Mags.Push(sc.Mags[0]);
				}

				T.Destroy();
				break;

			case 'HDMagicShield':
				Inventory(T).Icon = TexMan.CheckForTexture("USGIA0");
				break;

			case 'SpentShield':
				let yascd = Actor.Spawn("YetAnotherSpentShield", T.Pos);
				yascd.Vel = T.Vel;
				T.Destroy();
				break;
		}

		if (!yasc) return;

		yasc.Vel = T.Vel;
	}
}
