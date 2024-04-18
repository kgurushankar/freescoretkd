<?php 
	include( __DIR__ . './../../../session.php' );
	include( __DIR__ . '/../../../include/php/config.php' ); 
  $ringnum = isset( $_GET[ 'ring' ]) ? intval( $_GET[ 'ring' ]) : null;
  $divid   = isset( $_GET[ 'divid' ]) ? $_GET[ 'divid' ] : null;
?>
<html>
	<head>
		<link href="../../../include/bootstrap/css/bootstrap.min.css" rel="stylesheet" />
		<link href="../../../include/alertify/css/alertify.min.css" rel="stylesheet" />
		<link href="../../../include/alertify/css/themes/default.min.css" rel="stylesheet" />
		<script src="../../../include/jquery/js/jquery.js"></script>
		<script src="../../../include/jquery/js/jquery-ui.min.js"></script>
		<script src="../../../include/bootstrap/js/bootstrap.min.js"></script>
		<script src="../../../include/alertify/alertify.min.js"></script>
		<style>
.summary { font-weight: bold; font-size: 1.2em; }
		</style>
	</head>
	<body>
		<div id="report-tabular" class="container"></div>
		<script type="text/javascript">
			var tournament = <?= $tournament ?>;
			var ring       = { num : 1 };
			var ws         = new WebSocket( `<?= $config->websocket( 'worldclass' ) ?>/${tournament.db}/${ring.num}/computer+operator` );
			var network    = { reconnect: 0 };
			var divisions  = [];
      var selected   = { ring : <?= is_null( $ringnum ) ? 'null' : $ringnum ?>, divid : <?= is_null( $divid ) ? 'null' : "'$divid'" ?> };

			network.send = data => {
					let request  = { data };
					request.json = JSON.stringify( request.data );
					ws.send( request.json );
			};

			var display = {
				progress : {
					summary : progress => {
            let complete = Math.floor((progress.complete / progress.count ) * 100);
						let division = progress.division;
						let summary  = `<div class="row"><div class="col-sm-2">${progress.label}</div><div class="summary col-sm-6">${division}</div><div class="col-sm-4"><div class="progress"><div class="progress-bar" role="progressbar" style="width: ${complete}%;">${complete}%</div></div></div></div>`;
						$( '#report-tabular' ).append( '<div class="division">', summary, "</div>" );
					},
					table : division => {
            if( selected.ring && division.ring != selected.ring ) { return; }
            if( selected.divid && division.name != selected.divid ) { return; }
						let rounds   = [{ code : 'finals', name : 'Final' }];
						let n        = division.athletes.length;

						if( n >   8 ) { rounds.push({ code : 'semfin', name : 'Semi-Final' }); }
						if( n >= 20 ) { rounds.push({ code : 'prelim', name : 'Preliminary' }); }
						if( 'flight' in division ) {
							rounds = [{ code : 'prelim', name : 'Preliminary' }];
						}

						console.log( 'RING', division.ring );
            let progress = { ring : division.ring == 'staging' ? 0 : division.ring, count : 0, complete : 0 };
						
						rounds.forEach( round => {

							let placements = round.code in division.placement ? division.placement[ round.code ] : [];
              let pending    = round.code in division.pending ? division.pending[ round.code ] : [];
              let n          = placements.length + pending.length;
              let complete   = Math.floor(( placements.length / n) * 100);

              if( n == 0 ) { return; }

              progress.complete += placements.length;
              progress.count    += n;
						});

						return progress;
					}
				}
			};

			var handle = {
				tournament : {
					read : update => {
						let divisions = update.divisions.sort(( a, b ) => a.name.localeCompare( b.name ));
						let n         = update.divisions.reduce(( a, b ) => a > b.ring ? a : b.ring, 0 );
						let progress  = { label: 'Recognized Poomsae', count: 0, complete: 0, division: '', rings : [] };
						for( let i = 0; i <= n; i++ ) { progress.rings[ i ] = { label : `Ring ${i}`, count : 0, complete: 0, division: { name: '', description : '' }}; }

						$( '#report-tabular' ).empty();
						divisions.forEach( division => { 
							let divprog = display.progress.table( division ); 
							let i       = divprog.ring;
							progress.count               += divprog.count;
							progress.complete            += divprog.complete;
							progress.rings[ i ].count    += divprog.count;
							progress.rings[ i ].complete += divprog.complete;
						});
						display.progress.summary( progress );
					}
				}
			};

			ws.onerror = network.error = () => {
				setTimeout( function() { location.reload(); }, 15000 ); // Attempt to reconnect every 15 seconds
			};

			ws.onopen = network.connect = () => {
				network.send({ type : 'tournament', action : 'read' });
			};

			ws.onmessage = network.message = response => {
				let update  = JSON.parse( response.data );
				let request = update.request;
				console.log( update );

				let type = request.type;
				if( ! (type in handle)) { alertify.error( `No handler for ${type} object` ); console.log( update ); return; }
				let action = request.action;
				if( ! (action in handle[ type ])) { alertify.error( `No handler for ${action} action` ); console.log( update ); return; }

				handle[ type ][ action ]( update );
			};

			// ===== TRY TO RECONNECT IF WEBSOCKET CLOSES
			ws.onclose = network.close = () => {
				if( network.reconnect < 10 ) { // Give 10 attempts to reconnect
					// Try to reconnect in 3 seconds
					setTimeout(() => {
						if( network.reconnect == 0 ) { alertify.error( 'Network error. Trying to reconnect.' ); }
						network.reconnect++;
						ws = new WebSocket( `<?= $config->websocket( 'worldclass' ) ?>/${tournament.db}/${ring.num}/computer+operator` ); 
						
						ws.onerror   = network.error;
						ws.onmessage = network.message;
						ws.onclose   = network.close;
					}, 3000 );
				}
			};

		</script>
	</body>
</html>
