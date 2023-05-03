<?php 
	include( "../../../include/php/config.php" ); 
	$t = json_decode( $tournament );
?>
<html>
	<head>
		<link href="../../../include/bootstrap/css/bootstrap.min.css" rel="stylesheet" />
		<link href="../../../include/bootstrap/css/freescore-theme.min.css" rel="stylesheet" />
		<link href="../../../include/alertify/css/alertify.min.css" rel="stylesheet" />
		<link href="../../../include/alertify/css/themes/default.min.css" rel="stylesheet" />
		<link href="../include/css/test/client.css" rel="stylesheet" />
		<script src="../../../include/jquery/js/jquery.js"></script>
		<script src="../../../include/jquery/js/jquery-ui.min.js"></script>
		<script src="../../../include/jquery/js/jquery.howler.min.js"></script>
		<script src="../../../include/jquery/js/jquery.tappy.js"></script>
		<script src="../../../include/jquery/js/jquery.cookie.js"></script>
		<script src="../../../include/bootstrap/js/bootstrap.min.js"></script>
		<script src="../../../include/js/freescore.js"></script>
		<script src="../include/js/score.js"></script>
		<script src="../include/js/athlete.js"></script>
		<script src="../include/js/division.js"></script>
		<script src="../../../include/alertify/alertify.min.js"></script>

		<meta name="viewport" content="width=device-width, initial-scale=1">
		<meta charset="UTF-8">
		<meta name="google" content="notranslate">
		<meta http-equiv="Content-Language" content="en">
	</head>
	<body>
		<div class="container">
			<div id="ring" class="btn-group" data-toggle="buttons">
				<?php foreach( $t->rings as $ring ): ?>
					<label class="btn btn-primary"><input type="radio" name="ring" value="<?= $ring ?>">Ring <?= $ring ?></label>
				<?php endforeach; ?>
			</div>

			<div id="athlete"></div>
			<div id="send"><a id="send-scores" class="btn btn-success disabled">Send scores</a><a id="send-one-score" class="btn btn-success disabled" style="margin-left: 40px;">Send One Score</a></div>

		</div>
		<script>
			var sound      = {};
			var division   = undefined;
			var tournament = <?= $tournament ?>;
			var ring       = { num: 1 };
			var ws         = undefined;

			sound.ok    = new Howl({ urls: [ "../../../sounds/upload.mp3",   "../../../sounds/upload.ogg" ]});
			sound.error = new Howl({ urls: [ "../../../sounds/quack.mp3",    "../../../sounds/quack.ogg"  ]});
			sound.next  = new Howl({ urls: [ "../../../sounds/next.mp3",     "../../../sounds/next.ogg"   ]});
			sound.prev  = new Howl({ urls: [ "../../../sounds/prev.mp3",     "../../../sounds/prev.ogg"   ]});

			$( "input[type=radio][name='ring']"   ).change(( e ) => { 
				ring.num = $( e.target ).val(); 
				if( defined( ws )) { ws.close(); }
				ws = new WebSocket( `<?= $config->websocket( 'breaking' ) ?>/${tournament.db}/${ring.num}/tester` );

				ws.onopen = () => {
					let request  = { data : { type : 'division', action : 'read' }};
					request.json = JSON.stringify( request.data );
					ws.send( request.json );
				};

				ws.onmessage = ( response ) => {
					let update = JSON.parse( response.data );
					console.log( update );

					if( defined( update.error )) {
						if( update.error.match( /Division not in ring/i )) { alertify.error( "No division in ring " + ring.num ); }
					}

					if( ! defined( update.division )) { return; }

					division = new Division( update.division );
					if( ! defined( division )) { return; }

					if( update.action == 'update' && update.type == 'division' ) {
						let athlete = division.current.athlete()
						$( '#send-scores, #send-one-score' ).removeClass( 'disabled' );
						$( '#athlete' ).html( athlete.name() );
					}
				};
			});

			let rand = ( x ) => { return Math.floor( Math.random() * x ); };
			let create_scores = ( j ) => {
				let skills = [ 5, 6, 6, 6, 6, 7, 7, 8 ];
				let skill  = skills[ rand( 8 ) ];
				let scores = [];

				for( i = 0; i < j; i++ ) {
					let score  = {"presentation":{"creativity":0.0,"rhythm":0.0,"style":0.0,"technique":0.0},"technical":{"difficulty":0}};
					[ 'creativity', 'rhythm', 'style', 'technique' ].forEach(( p ) => { score.presentation[ p ] = ((skill) + parseInt( rand( 3 )))/10; });
          score.technical.difficulty = (12 + (2 * rand( skill )))/10;

          if( i == 0 ) {
            let minor = rand( 10 ) - skill;
            let major = rand( 12 ) - skill;
            let proc  = rand( 10 ) - skill;
            score.technical.deductions = {};
            score.technical.deductions.minor = minor > 0 ? rand( minor )/10 : 0;
            score.technical.deductions.major = major > 0 ? (rand( major ) * 3)/10 : 0;
            score.procedural = { deductions :  proc  > 0 ? (rand( proc ) * 3)/10  : 0 };
          }

					scores.push( score );
				}

				return scores;
			}

			$( '#send-scores' ).off( 'click' ).click(() => {
				let request = undefined;
				let j       = division.judges();
				let scores  = create_scores( j );
				let athlete = division.current.athlete();

				sound.ok.play();
				for( i = 0; i < j; i++ ) {
					let send = ( i, scores ) => { return () => {
						$.cookie( 'judge', i );
						alertify.notify( 'Score for ' + athlete.name() + ' sent for ' + ( i == 0 ? 'Referee' : 'Judge ' + i ));
						score        = scores[ i ];
						request      = { data : { type : 'division', action : 'score', score: score, judge: i, cookie : { judge: i }}};
						request.json = JSON.stringify( request.data );
						ws.send( request.json );
						console.log( request.data );
					}};
					setTimeout( send( i, scores ), (((i + rand( 5 )) * 500) + rand( 250 )));
				}
			});

			$( '#send-one-score' ).off( 'click' ).click(() => {
				let request = undefined;
				let j       = division.judges();
				let scores  = create_scores( j );
				let athlete = division.current.athlete();
				let i       = rand( j );

				sound.ok.play();
				let send = ( i, score ) => { return () => {
					$.cookie( 'judge', i );
					alertify.notify( 'Score for ' + athlete.name() + ' sent for ' + ( i == 0 ? 'Referee' : 'Judge ' + i ));
					request      = { data : { type : 'division', action : 'score', score: score, judge: i, cookie : { judge: i }}};
					request.json = JSON.stringify( request.data );
					ws.send( request.json );
					console.log( request.data );
				}};
				send( i, scores[ i ] )();
			});

		</script>
	</body>
</html>
