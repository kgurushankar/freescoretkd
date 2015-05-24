
$.widget( "freescore.divisionEditor", {
	options: { autoShow: true },
	_create: function() {
		var o = this.options;
		var e = this.options.elements = {};

		var html      = e.html      = FreeScore.html;
		var edit      = e.edit      = html.div.clone();
		var header    = e.header    = html.div.clone() .divisionHeader( o );

		var rounds    = e.rounds    = {
			tabs   : html.div.clone() .attr( "data-role", "tabs" ),
			navbar : html.div.clone() .attr( "data-role", "navbar" ),
			prelim : { button : html.li.clone(), tab : html.div.clone() .attr( "id", "prelim" ), list : html.ul.clone() .attr( "data-role", "listview" ) },
			semfin : { button : html.li.clone(), tab : html.div.clone() .attr( "id", "semfin" ), list : html.ul.clone() .attr( "data-role", "listview" ) },
			finals : { button : html.li.clone(), tab : html.div.clone() .attr( "id", "finals" ), list : html.ul.clone() .attr( "data-role", "listview" ) },
		};

		var actions   = e.actions   = {
			athlete : { 
				name     : html.div.clone(),
				accept   : html.a.clone(),
				reset    : html.a.clone(),
				remove   : html.a.clone(),
				close    : html.a.clone(),
			}
		}
		actions.athlete.name
			.html( "Name" );

		actions.athlete.reset
			.addClass( "ui-btn ui-icon-back ui-btn-icon-left" )
			.html( "Clear Score" )
			.click( function( ev ) { } );

		actions.athlete.remove
			.addClass( "ui-btn ui-icon-minus ui-btn-icon-left" )
			.html( "Remove" )
			.click( function( ev ) { } );

		actions.athlete.close
			.addClass( "ui-btn ui-icon-delete ui-btn-icon-left" )
			.html( "Cancel" )
			.attr( "href", "#list" )
			.attr( "data-rel", "close" );

		edit 
			.attr( "data-role", "panel" ) 
			.attr( "data-position", "right" ) 
			.attr( "data-display", "overlay" ) 
			.attr( "data-theme", "b" ) 
			.attr( "id", "edit-panel" )
			.append( 
				actions.athlete.name, 
				actions.athlete.reset, 
				actions.athlete.remove, 
				actions.athlete.close 
			);

		var map = { prelim : "Preliminary Round", semfin : "Semi-Final Round", finals : "Final Round" };
		rounds.prelim.button.append( html.a.clone() .attr( "href", "#prelim" ) .attr( "data-ajax", false ) .html( map[ 'prelim' ] ));
		rounds.semfin.button.append( html.a.clone() .attr( "href", "#semfin" ) .attr( "data-ajax", false ) .html( map[ 'semfin' ] ));
		rounds.finals.button.append( html.a.clone() .attr( "href", "#finals" ) .attr( "data-ajax", false ) .html( map[ 'finals' ] ));
		rounds.navbar.append( html.ul.clone().append( rounds.prelim.button, rounds.semfin.button, rounds.finals.button ));
		rounds.prelim.tab.append( rounds.prelim.list );
		rounds.semfin.tab.append( rounds.semfin.list );
		rounds.finals.tab.append( rounds.finals.list );
		rounds.tabs.append( rounds.navbar, rounds.prelim.tab, rounds.semfin.tab, rounds.finals.tab );
		rounds.navbar.enhanceWithin();

		this.element .append( edit, header, rounds .tabs );
	},

	_init: function() {
		var e       = this.options.elements;
		var o       = this.options;
		var html    = e.html;

		var addAthlete = function( i ) {
			var athlete = { 
				index    : i,
				data     : o.division.athletes[ i ],
				name     : html.text .clone() .addClass( "name" ) .attr( "id", "athlete-name-" + i ),
				view     : html.div  .clone() .addClass( "athlete" ),
				actions  : html.div.clone(),
				edit     : html.a.clone(),
				listitem : html.li.clone() .attr( "data-icon", "ui-icon-user" ),
			};

			athlete.view.addClass( "athlete" );
			athlete.name .attr( "index", i );
			athlete.name .val( athlete.data.name );
			athlete.name .click( function( ev ) { $( this ).select(); } );
			athlete.name .keydown( function( ev ) { 
				var i       = $( this ).attr( "index" );
				var oldName = o.division.athletes[ i ].name;
				var newName = $( this ).val();
				if      ( ev.which == 13 ) { 
					o.division.athletes[ i ].name = newName; 
					$( this ).blur(); 
					console.log( "AJAX call to change name from '" + oldName + "' to '" + newName + "' for athlete " + i );

				} else if ( ev.which == 27 ) { $( this ).val( oldName ); }
			});

			athlete.edit
				.addClass( "edit ui-btn ui-icon-edit ui-btn-icon-notext ui-btn-inline" )
				.attr( "index", i )
				.click( function( ev ) { 
					var i = $( this ).attr( "index" ); 
					var athlete = o.division.athletes[ i ];
					o.current = i;
					e.actions.athlete.name.html( athlete.name ); 
					e.edit.panel( "open" ); 
				});

			athlete.view.append( athlete.name, athlete.edit );
			athlete.listitem.append( athlete.view );

			return athlete;
		}

		var n = defined( o.division.athletes ) ? o.division.athletes.length : 0;
		e.header.divisionHeader({ text : o.division.description, forms : o.division.forms, judges : o.division.judges, athletes : n });
		var min = undefined;


		for( var r = 0; r < 3; r++ ) {
			var rname = [ 'prelim', 'semfin', 'finals' ][ r ];
			if( ! defined( o.division.order )) continue;
			var order = o.division.order[ rname ];
			if( ! defined( order )) continue;

			// ===== ADD NAVIGATION BUTTON
			if( ! defined( min )) { min = r; }
			console.log( rname );
		}

		for( var r = min; r < 3; r++ ) {
			var rname = [ 'prelim', 'semfin', 'finals' ][ r ];
			var order = o.division.order[ rname ];
			var round = e.rounds[ rname ];
			round.list.empty();

			// TODO set up the round to display
			for( var i in order ) {
				var j = order[ i ];
				var athlete = addAthlete( j );
				round.list.append( athlete.listitem );

				e.edit.panel();
				round.list.listview().listview( "refresh" );
			};
		}
	},
});
