--[[
	Map Sweepers - Co-op NPC Shooter Gamemode for Garry's Mod by "Octantis Addons" (consisting of MerekiDor & JonahSoldier)
    Copyright (C) 2025-2026 MerekiDor

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

	See the full GNU GPL v3 in the LICENSE file.
	Contact E-Mail: merekidorian@gmail.com
--]]

jcms.codex = {
	{ 
		level = 1,
		name = [=[The Map Sweepers Initiative]=],
		entry = {
			{ 
				type = "title", 
				text = [=[Map Sweepers]=] 
			},

			{ 
				type = "text", 
				text = [=[Code: JCMS]=] 
			},

			{ 
				type = "text", 
				text = [=[A massive project first launched by J Corp in 2925 that you, dear sweeper, are now part of. The goal of the project is simple: put as many NPCs into the ground as possible. Why? For business.]=]
			},

			{ 
				type = "text", 
				text = [=[J Corp spends a shitload of resources - financial and human - on this project out of sheer spite towards NPCs, and gains very little out of it (despite its claims of profitability).]=]
			},

			{ 
				type = "text", 
				text = [=[Who are the Sweepers themselves? Well, truth is, they aren't even J Corp employees. The corporation picks volunteers and random people off the streets for this job. There's a little test they have to pass, of course. They must:]=]
			},

			{
				type = "list_numbered",
				entries = {
					[=[Be capable of telling friends and enemies apart (optional)]=],
					[=[Know how to use a weapon (optional)]=],
					[=[Do some damage]=]
				}
			},

			{ 
				type = "text", 
				text = [=[If they meet all of these conditions, they can become a Sweeper! If they don't, they can become a Sweeper, too. The corporation then gives them unrestricted access to firearms, energy weapons, explosives, automated defenses, armed vehicles, orbital lasers and even nukes (but only if they ask nicely). Sweepers are then delivered to various points of interest across the multiverse and the Jity to kill everything that does not have a human brain.]=]
			},

			{ 
				type = "text", 
				text = [=[This entire operation earns J Corp basically nothing. The "J Credits" that the Sweepers get during their missions are an in-corporation currency, which makes them completely useless everywhere else. Despite this, there are billions (trillions on weekends) of people standing in lines, eagerly waiting for their turn to become a Sweeper.]=]
			}
		}
	},

	{
		level = 4,
		name = [=[The World ("Clashverse")]=],
		entry = {
			{ 
				type = "title", 
				text = [=[[META] Clashverse]=] 
			},

			{ 
				type = "text", 
				text = [=["Clashverse" is the name of the universe this addon is set in, and originates from a private Discord server where the creators and beta testers of the addon dwell.]=] 
			},

			{ 
				type = "text", 
				text = [=[The year is (current year + 900). Planet Earth, nearby outer space and an unknown number of other universes are wholly consumed by "Jity Jeventeen", and control is *perfectly and evenly* split between three factions: J Corp, RGG and Mafia.]=] 
			},

			{ 
				type = "text", 
				text = [=[Rather than describing exactly what this is all about, let's just go over some of the basics for you to get the idea:]=] 
			},

			{ 
				type = "list_points",
				entries = {
					[=[Life in the universe has become one big shitpost. Videogame and meme logic apply in real life.]=], --Not sure I like it being described as a shitpost -j
					[=[Every fictional character exists, and every videogame/movie/book/whatever universe exists as part of Clashverse. The only difference is that they usually get recolored or assigned to one of the three existing factions. For instance the "Third Street Saints" from "Saints Row" become part of the RGG, because they're purple.]=],
					[=[People can't die, they respawn in 15 seconds. Despite this, everyone is still afraid of death, and people think that killing someone is a means to an end. Entire "revenge plots" take place, then the killed guy respawns nearby and everyone pretends nothing happened.]=],
					[=[Things happen if people expect them to happen. Everything is contrived. That being said, movie/drama logic and tropes apply to almost everything.]=],
					[=[Thousands of world-ending scenarios happen every day. That's pretty normal. Nuclear war? Typical Sunday. Alien invasion? Still gotta get to the office. The fog is coming? Sure, that one's gotten old by now.]=],
					[=[The population of the world is massive. The world's most powerful supercomputer is still calculating exactly how many people live in the Jity. The number has over a quadrillion digits now, and thousands of digits are added every second.]=],
					[=[Everyone who has ever lived and died in history, is now alive. As soon as the respawn system was set up, a fucking door just kinda appeared in Heaven, Hell, Purgatory and everyone else just led people into the Jity. The only person who remained in the underworld is Sisyphus. He's still pushing that boulder.]=],
					[=[Time and space are compressed in various places. You could walk into a small shack and have an entire planet stuffed into it. Africa is in slow motion just to make the statement "every 60 seconds in Africa a minute passes" false. Factories and workplaces are accelerated thousandfold. Anything goes.]=]
				}
			},

			{ 
				type = "text", 
				text = [=[You can go look up various cursed images and other uncanny shit and it'll be perfectly canon and normal in Clashverse.]=] 
			},
		}
	},

	{
		level = 7,
		name = [=[Factions of the World]=],
		entry = {
			{ 
				type = "title", 
				text = [=[Factions]=] 
			},

			{ 
				type = "text",
				text = [=[As mentioned in the previous entry, control over the world is evenly split between three rivaling factions: J Corp, RGG and Mafia. Every single other faction that exists or could exist is a subsidiary of one of these three major factions, based on how similar their motives, goals & aesthetics are.]=]
			},

			{ 
				type = "text",
				text = [=[Districts, maps, cities, planets and universes controlled by a faction get their IRL shader/color modifier/fog color changed to the color of that faction. Inversely, if a location naturally features a color that matches a faction, then that location is automatically owned by that faction. For instance, most deserts are owned by Mafia; Xen is owned by RGG; Mars is owned by J Corp. Of course, there are exceptions, and if RGG was to invade Mars, for example, it would partially turn purple-ish as long as you're within RGG territory.]=]
			},
			
			{ 
				type = "text",
				text = [=[These factions are at war with each other for absolutely no reason. However, this does not stop them from cooperating with each other randomly. Sometimes, RGG may gang up against Mafia together with J Corp. Sometimes J Corp can lend weapons and personnel to Mafia to help them attack J Corp. Sometimes the same faction just goes against itself, it simply happens. No hard feelings.]=]
			},

			{ 
				type = "title", 
				text = [=[J Corp]=] 
			},

			{ 
				type = "caption", 
				text = [=[Led by JonahSoldier, second-in-command: MerekiDor]=] 
			},

			{ 
				type = "text",
				text = [=[A comically evil government-slash-corporate entity. Produces nothing useful, and exists solely to be as evil and malicious as possible. Oppresses people and does evil shit for the sake of doing evil shit. J Corp is responsible for the "taxation" of the population - those taxes don't actually go anywhere, not even to J Corp itself, that cash is just permanently lost. The corporation hates the environment and causes as much pollution as possible.]=]
			},

			{
				type = "text",
				text = [=[Uses the color red, hates the color blue. J Corp is also responsible for doing mildly annoying things, such as sticking their propaganda posters on every wall and door using that nasty type of glue that makes the paper very hard to peel off cleanly.]=]
			},

			{
				type = "text",
				text = [=[Many "evil/greedy CEO" and "evil overlord" villains from other universes work for J Corp. They also get a pass if they're red or love money. Some examples:]=]
			},

			{
				type = "list_numbered",
				entries = {
					[=[Dr. Breen (Half-Life 2)]=],
					[=[Hoyt Walker (Far Cry 3)]=],
					[=[Bob Page (Deus Ex)]=],
					[=[Darth Vader (Star Wars)]=],
					[=[Philippe Loren (Saints Row: The Third)]=],
					[=[Edward Diego (System Shock)]=],
					[=[Cave Johnson (Portal 2)]=],
					[=[Daniel Plainview (There Will Be Blood, 2007)]=],
					[=[Ayin (Lobotomy Corporation)]=],
					[=[Dr. Doofenshmirtz (Phineas and Ferb)]=],
					[=[Jeremy Blaire (Outlast)]=],
					[=[You, if you like the colour red. Or money.]=],
				}
			},

			{
				type = "text",
				text = [=[Aesthetic/mood: blocky, hostile, dystopian, concrete and metal, factories and pipes, ridiculous level of industrialization, etc.]=]
			},

			{ 
				type = "title", 
				text = [=[RGG]=] 
			},

			{ 
				type = "caption", 
				text = [=[Led by Traeesen]=] 
			},

			{ 
				type = "text",
				text = [=[A [REDACTED] Gamblers Gang. As the name suggests, this is a bunch of chaotics thugs, rogues and insane gangbangers who gamble away all of their money as fast as they earn it. Members of this faction are perpetually broke, yet this faction still holds one third of the world, and somehow has the cleanest streets.]=]
			},

			{
				type = "text",
				text = [=[They are represented by these colours: purple, indigo, fuchsia. Almost every single 144p video on the internet with footage from second or third-world countries is a typical day in the RGG. They intenionally use comically cheap/makeshift stuff despite the availability of normal tech at their disposal. Despite this, RGG-owned districts are extremely fancy: they own many skyscrapers, palaces and mansions, they just don't use them out of principle. Their controlled territories look something like the City of Glass from Mirror's Edge: Catalyst. The RGG also owns the Synthwave (Retrowave) aesthetic.]=]
			},

			{
				type = "text",
				text = [=[Most "ragtag bunch of misfits", rebellious, idealist, crazy/unpredictable/chaotic characters, as well as street gangs, are part of the RGG. Some examples:]=]
			},
			
			{
				type = "list_numbered",
				entries = {
					[=[Jovian Sepratists (Barotrauma)]=],
					[=[The Fans (Hotline Miami 2)]=],
					[=[Third Street Saints gang (Saints Row series)]=],
					[=[Trevor Philips (GTA V)]=],
					[=[Llewelyn Moss (No Country for Old Men, 2007)]=],
					[=[The Joker (DC Comics)]=],
					[=[Aria T'Loak (Mass Effect)]=],
					[=[Tyler Durden (Fight Club, 1999)]=],
					[=[That one friend you know with a gambling addiction (Maybe you?)]=],
					[=[Almost every single animated series "power of friendship yay"-type group.]=]
				}
			},

			{ 
				type = "title", 
				text = [=[Mafia]=] 
			},

			{ 
				type = "caption",
				text = [=[Led by Xelerax]=] 
			},

			{ 
				type = "text",
				text = [=[Strangely enough, the only "lawful good" faction of the universe. Mafia gives loans to people in need, and is generally a very noble organization. They didn't know a "mafia" was supposed to be a criminal organisation until 3 years into doing business.]=]
			},

			{ 
				type = "text",
				text = [=[Their color scheme is yellow and orange, and their aesthetics combine: law enforcement, organized crime such as yakuza, sicilian mafia, south-american cartels; cowboys. Somehow. Almost everything associated with the colors, anyway.]=]
			},

			{
				type = "text",
				text = [=[Mafia runs whatever ""police force"" is out there in the world, and has MWAT teams full of special force members with tommy guns wearing fedoras. They may be corrupt and partake in illegal activities at times, but mostly for the greater good in the end. Examples of characters and organizations working for Mafia:]=]
			},

			{
				type = "list_numbered",
				entries = {
					[=[Gordon Freeman (Half-Life 2)]=],
					[=[The Spokesman (XCOM)]=],
					[=[David Sarif (Deus Ex)]=],
					[=[The Protectorate (Starbound)]=],
					[=[Tony Montana (Scarface, 1983)]=],
					[=[Max Payne (Max Payne)]=],
					[=[Arthur Morgan (Red Dead Redemption 2)]=],
					[=[The Thumb (Library of Ruina)]=],
					[=[Papyrus & Sans (Undertale)]=],
					[=[Kazuma Kiryu (Yakuza)]=],
					[=[GDI (Command & Conquer Tiberium Universe)]=]
				}
			}
		}
	}
}