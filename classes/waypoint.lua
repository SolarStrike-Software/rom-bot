WPT_NORMAL = 3;
WPT_TRAVEL = 4;		-- don't target
WPT_RUN = 5;		-- don't target, don't fight back

CWaypoint = class(
	function (self, _X, _Z)
		-- If we're copying from a waypoint
		if( type(_X) == "table" ) then
			local copyfrom = _X;
			self.X = copyfrom.X;
			self.Z = copyfrom.Z;
			self.Action = copyfrom.Action;
			self.Type = copyfrom.Type;
		else
			self.X = _X;
			self.Z = _Z;
			self.Action = nil; -- String containing Lua code to execute when reacing the point.
			self.Type = WTP_NORMAL;
		end

		if( not self.X ) then self.X = 0.0; end;
		if( not self.Z ) then self.Z = 0.0; end;
	end
);

function CWaypoint:update()
	-- Does nothing. Just for compatability with
	-- pawn class (so we can interchange if moving
	-- to a target, instead)
end