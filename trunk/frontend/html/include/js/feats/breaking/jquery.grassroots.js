$.widget( "freescore.grassroots", {
	options: { autoShow: true },
	_create: function() {
		var o           = this.options;
		var e           = this.options.elements = {};
		var widget      = this.element;
		var html        = { div : $( "<div />" ) };
		var leaderboard = e.leaderboard = html.div.clone() .addClass( "back" );
		var scoreboard  = e.scoreboard  = html.div.clone() .addClass( "front" );
		var tiebreaker  = e.tiebreaker  = html.div.clone() .addClass( "front" );
		var usermessage = e.usermessage = html.div.clone() .addClass( "usermessage" );
		var card        = e.card        = html.div.clone() .addClass( "card" );

		card .append( leaderboard, scoreboard, tiebreaker );
		widget .addClass( "grassroots flippable" );
		widget .append( card, usermessage );
	},
	_init: function( ) {
		var e = this.options.elements;
		var o = this.options;

		function refresh( update ) {
			var progress = JSON.parse( update.data );
			var division = progress.divisions.find((d) => { return d.name == progress.current; } );
			var athlete  = division.athletes[ division.current ];

			o.tiecache   = defined( division.tied ) ? division.tied[ 0 ] : o.tiecache;
			if( defined( division.error )) {
				e.card.fadeOut();
				e.usermessage.html( division.error );
				e.usermessage.fadeIn( 500 );

			} else if( division.state == 'tiebreaker' ) {
				if( e.card.hasClass( 'flipped' )) { e.card.removeClass( 'flipped' ); }
				var tie      = defined( division.tied ) ? division.tied.shift() : o.tiecache;
				var athletes = tie.tied.map( function( i ) { return division.athletes[ i ]; });
				var title    = ordinal( tie.place ) + ' Place Tiebreaker';
				// ===== SHOW TIEBREAKER BY VOTE
				if( tie.tied.length == 2 ) {
					e.scoreboard.hide();
					e.tiebreaker.show();
					e.tiebreaker.voteDisplay({ title: title, athletes : athletes, judges : division.judges });

				// ===== SHOW TIEBREAKER BY SCORE
				} else {
					e.scoreboard.show();
					e.tiebreaker.hide();
					e.scoreboard.scoreboard( { title: title, current: { athlete : athlete }, judges : division.judges } );
				}
				
			} else if( defined( division.mode ) && division.mode == 'single-elimination' && division.state == 'score' ) {
				if( e.card.hasClass( 'flipped' )) { e.card.removeClass( 'flipped' ); }

				var athletes = [];
				var i        = division.current;
				var j        = 0;
				while( i >= division.brackets[ j ].length ) { i -= division.brackets[ j ].length; j++; }
				var bracket  = division.brackets[ j ][ i ];

				var blue = new Athlete( division.athletes[ bracket.blue.athlete ]);
				var red  = defined( bracket.red.athlete ) ? new Athlete( division.athletes[ bracket.red.athlete ]) : { display : { name : () => { return '<span style="opacity: 0.5;">Bye</span>' }}};
				athletes.push({ name : blue.display.name(), votes : bracket.blue.votes });
				athletes.push({ name : red.display.name(),  votes : bracket.red.votes });

				e.scoreboard.hide();
				e.tiebreaker.show();
				e.tiebreaker.voteDisplay({ title: title, athletes : athletes, judges : division.judges });

			} else if( division.state == 'display' ) {
				
				if( ! e.card.hasClass( 'flipped' )) { e.card.addClass( 'flipped' ); }

				if( defined( division.mode ) && division.mode == 'single-elimination' ) {
					var i        = division.current;
					var j        = 0;
					while( i >= division.brackets[ j ].length ) { i -= division.brackets[ j ].length; j++; }
					var bracket  = division.brackets[ j ][ i ];
					console.log( 'SHOW BRACKET', i, j );
					e.leaderboard.leaderboard( { division : division, round: j, current: i });
				} else {
					e.leaderboard.leaderboard( { division : division } );
				}

			} else {
				if( e.card.hasClass( 'flipped' )) { e.card.removeClass( 'flipped' ); }
				e.scoreboard.show();
				e.tiebreaker.hide();
				e.scoreboard.scoreboard( { current: { athlete : athlete }, judges : division.judges } );
			}
		};

		e.source = new EventSource( '/cgi-bin/freescore/forms/grassroots/update?tournament=' + o.tournament.db + '&ring=' + o.ring.num );
		e.source.addEventListener( 'message', refresh, false );

	}
});
