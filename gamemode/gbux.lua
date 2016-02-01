--[[-------------------------------------------------------

Fight to Survive: Stronghold by RoaringCow, TehBigA is licensed under a Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported License.

This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/3.0/ or send a letter to Creative Commons,
444 Castro Street, Suite 900, Mountain View, California, 94041, USA.

---------------------------------------------------------]]
concommand.Add( "sh_buyitem",
	function( ply, cmd, args )
		ply:BuyItem( tonumber(args[1]), args[2], tonumber(args[3]) )
	end )

local function CCGiveAwayMoney( ply, cmd, args )
	local givingto = Entity( tonumber(args[1]) )
	local amount = tonumber( args[2] )

	if amount < 0 then
		ply:SendLua( [[chat.AddText(Color(200,200,200,255),"Stronghold: ",Color(200,50,50,255),"Can not give negative money!")]] )
		ply:SendLua( [[surface.PlaySound( "buttons/button16.wav" )]] )
		return
	end

	if IsValid( givingto ) then
		if ply:GetMoney() - amount > 0 then
			ply:AddMoney( amount * -1 )
			givingto:AddMoney( amount )
			ply:SaveMoney()
			givingto:SaveMoney()

			ply:SendLua( [[chat.AddText(Color(200,200,200,255),"Stronghold: ",Color(200,50,50,255),"]]..UTIL_FormatMoney( UTIL_PRound(amount,2))..[[ given to ]]..sql.SQLStr(givingto:GetName(),true)..[[.")]] )
			ply:SendLua( [[surface.PlaySound( "buttons/button15.wav" )]] )
			givingto:SendLua( [[chat.AddText(Color(200,200,200,255),"Stronghold: ",Color(200,50,50,255),"You have been given ]]..UTIL_FormatMoney( UTIL_PRound(amount,2))..[[ by ]]..sql.SQLStr(ply:GetName(),true)..[[.")]] )
			givingto:SendLua( [[surface.PlaySound( "buttons/button15.wav" )]] )
		else
			ply:SendLua( [[chat.AddText(Color(200,200,200,255),"Stronghold: ",Color(200,50,50,255),"You do not have that much money!")]] )
			ply:SendLua( [[surface.PlaySound( "buttons/button16.wav" )]] )
		end
	else
		ply:SendLua( [[chat.AddText(Color(200,200,200,255),"Stronghold: ",Color(200,50,50,255),"That player does not exist!")]] )
		ply:SendLua( [[surface.PlaySound( "buttons/button16.wav" )]] )
	end
end

local function AutoCompleteGiveAwayMoney( commandName, args )
	return { "sh_giveawaymoney <Entity ID of player> Amount" }
end
concommand.Add( "sh_giveawaymoney", CCGiveAwayMoney, AutoCompleteGiveAwayMoney )

function SH_SendClientItems( ply )
	if !IsValid( ply ) then return end

	local items = ply:GetItems()
	if !items then return end

	net.Start("sh_items")
		net.WriteTable(items)
	net.Send(ply)
end

function SH_SendClientItem( ply, name )
	if !IsValid( ply ) then return end

	local item = ply:GetItem( name )
	if !item then return end

	net.Start("sh_item")
		net.WriteTable({[name]=item})
	net.Send(ply)
end

function SH_SendClientLicenses( ply )
	if !IsValid( ply ) then return end

	local licenses = ply:GetLicenses()
	if !licenses then return end

	net.Start("sh_licenses")
		net.WriteTable(licenses)
	net.Send(ply)
end

function SH_SendClientLicense( ply, type, class )
	if !IsValid( ply ) then return end

	local license = ply:GetLicense( type, class )
	if !license then return end

	net.Start("sh_license")
		net.WriteTable({[type]={[class]=license}})
	net.Send(ply)
end

function GBuxAddMoney( ply, command, args )
	if IsValid( ply ) and !ply:IsAdmin() then return end

	if !args or #args < 2 then
		if IsValid( ply ) then
			ply:PrintMessage( HUD_PRINTCONSOLE, "Usage: gbux_addmoney <partial name> <money>\n" )
		else
			Msg( "Usage: gbux_addmoney <partial name> <money>\n" )
		end
		return
	end

	local found = 0
	local p = nil

	for _, v in ipairs(player.GetAll()) do
		if string.find(string.lower(v:GetName()),string.lower(args[1])) then
			found = found + 1
			p = v
		end
	end

	if found == 0 then
		if IsValid( ply ) then
			ply:PrintMessage( HUD_PRINTCONSOLE, "GBux: No player found." )
		else
			Msg( "GBux: No player found.\n" )
		end
		return
	elseif found > 1 then
		if IsValid( ply ) then
			ply:PrintMessage( HUD_PRINTCONSOLE, "GBux: Multiple players found, more unique please!" )
		else
			Msg( "GBux: Multiple players found, more unique please!\n" )
		end
		return
	end

	p:AddMoney( tonumber(args[2]) )

	if IsValid( ply ) then
		ply:PrintMessage( HUD_PRINTCONSOLE, "GBux: "..args[2].." given to "..p:GetName().."." )
	else
		Msg( "GBux: "..args[2].." given to "..p:GetName()..".\n" )
	end
end
concommand.Add( "gbux_addmoney", GBuxAddMoney )

function GBuxAddMoneyByID( ply, command, args )
	if IsValid( ply ) and !ply:IsAdmin() then return end

	if !args or #args < 2 then
		if IsValid( ply ) then
			ply:PrintMessage( HUD_PRINTCONSOLE, "Usage: gbux_addmoneybyid <steamid> <money>\n" )
		else
			Msg( "Usage: gbux_addmoneybyid <steamid> <money>\n" )
		end
		return
	end

	for _, v in ipairs(player.GetAll()) do
		if v:SteamID() == args[1] then
			v:AddMoney( tonumber(args[2]) )
			v:SaveMoney()
			if IsValid( ply ) then
				ply:PrintMessage( HUD_PRINTCONSOLE, "Player ("..v:GetName()..") was in the server, added money to player.\n" )
			else
				Msg( "Player ("..v:GetName()..") was in the server, added money to player.\n" )
			end
			return
		end
	end

	local filename = "Stronghold/PlayerInfo/"..string.gsub( args[1], ":", "_" )..".txt"
	local raw = file.Read( filename ) or ""
	local tbl = glon.decode( raw ) or {}

	tbl.Items = tbl.Items or {
		["buckshot"] = { type=3, count=1000 },
		["ar2"] = { type=3, count=1000 },
		["smg1"] = { type=3, count=1000 },
		["pistol"] = { type=3, count=1000 },
		["money"] = { type=0, count=100 }
	}
	tbl.Items["money"].count = tbl.Items["money"].count + tonumber( args[2] )


	local encoded = glon.encode( tbl )
	file.Write( filename, encoded )

	local str = !err and "GBux: "..tonumber(args[2]).." given to "..args[1]..".\n" or "SQL Error!\n"
	if IsValid( ply ) then
		ply:PrintMessage( HUD_PRINTCONSOLE, str )
	else
		Msg( str )
	end
end
concommand.Add( "gbux_addmoneybyid", GBuxAddMoneyByID )
