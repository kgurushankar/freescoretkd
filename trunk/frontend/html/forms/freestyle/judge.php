<?php 
	include( "../../include/php/config.php" ); 
?>
<html>
	<head>
		<link href="../../include/bootstrap/css/bootstrap.min.css" rel="stylesheet" />
		<link href="../../include/bootstrap/css/freescore-theme.min.css" rel="stylesheet" />
		<link href="../../include/css/forms/freestyle/judgeController.css" rel="stylesheet" />
		<script src="../../include/jquery/js/jquery.js"></script>
		<script src="../../include/jquery/js/jquery.howler.min.js"></script>
		<script src="../../include/jquery/js/jquery-ui.min.js"></script>
		<script src="../../include/jquery/js/jquery.tappy.js"></script>
		<script src="../../include/js/freescore.js"></script>
		<script src="../../include/js/forms/freestyle/jquery.deductions.js"></script>
		<script src="../../include/bootstrap/js/bootstrap.min.js"></script>
		<script src="../../include/bootstrap/add-ons/bootbox.min.js"></script>

		<meta name="viewport" content="width=device-width, initial-scale=1">
	</head>
	<body>
		<div class="container">
			<div id="technical-skills">
				<div class="alert alert-default" role="alert"><strong>Technical Skills</strong>
					<div id="technical-score" class="pull-right subtotal">0.0</div>
				</div>

				<button id="start" class="btn btn-lg btn-success">Start</button>

				<table class="mandatory-foot-technique-1">
					<tr>
						<th rowspan=2>Jumping side kick height</td>
						<td>
							<div class="performance-description">
								<div class="poor">Below belt</div>
								<div class="good">Body</div>
								<div class="very-good">Head</div>
								<div class="excellent">Above head</div>
								<div class="perfect"></div>
							</div>
						</td>
					</tr><tr>
						<td class="button-group">
							<div id="jumping-side-kick-height" class="btn-group" data-toggle="buttons">
								<label class="btn btn-danger" ><input type="radio" name="jumping-side-kick">0.0</label>
								<label class="btn btn-warning"><input type="radio" name="jumping-side-kick">0.1</label>
								<label class="btn btn-warning"><input type="radio" name="jumping-side-kick">0.2</label>
								<label class="btn btn-warning"><input type="radio" name="jumping-side-kick">0.3</label>
								<label class="btn btn-success"><input type="radio" name="jumping-side-kick">0.4</label>
								<label class="btn btn-success"><input type="radio" name="jumping-side-kick">0.5</label>
								<label class="btn btn-success"><input type="radio" name="jumping-side-kick">0.6</label>
								<label class="btn btn-primary"><input type="radio" name="jumping-side-kick">0.7</label>
								<label class="btn btn-primary"><input type="radio" name="jumping-side-kick">0.8</label>
								<label class="btn btn-primary"><input type="radio" name="jumping-side-kick">0.9</label>
								<label class="btn btn-default"><input type="radio" name="jumping-side-kick">1.0</label>
							</div>
						</td>
					</tr>
				</table>

				<table class="mandatory-foot-technique-2">
					<tr>
						<th rowspan=2>Number of front kicks in a jump</th>
						<td>
							<div class="performance-description">
								<div class="poor">&lt;3</div>
								<div class="good">3 Apchagi</div>
								<div class="very-good">4 Apchagi</div>
								<div class="excellent">5 Apchagi</div>
								<div class="perfect"></div>
							</div>
						</td>
					</tr><tr>
						<td class="button-group">
							<div id="jumping-front-kicks-count" class="btn-group" data-toggle="buttons">
								<label class="btn btn-danger" ><input type="radio" name="jumping-front-kicks">0.0</label>
								<label class="btn btn-warning"><input type="radio" name="jumping-front-kicks">0.1</label>
								<label class="btn btn-warning"><input type="radio" name="jumping-front-kicks">0.2</label>
								<label class="btn btn-warning"><input type="radio" name="jumping-front-kicks">0.3</label>
								<label class="btn btn-success"><input type="radio" name="jumping-front-kicks">0.4</label>
								<label class="btn btn-success"><input type="radio" name="jumping-front-kicks">0.5</label>
								<label class="btn btn-success"><input type="radio" name="jumping-front-kicks">0.6</label>
								<label class="btn btn-primary"><input type="radio" name="jumping-front-kicks">0.7</label>
								<label class="btn btn-primary"><input type="radio" name="jumping-front-kicks">0.8</label>
								<label class="btn btn-primary"><input type="radio" name="jumping-front-kicks">0.9</label>
								<label class="btn btn-default"><input type="radio" name="jumping-front-kicks">1.0</label>
							</div>
						</td>
					</tr>
				</table>
				<table class="mandatory-foot-technique-3">
					<tr>
						<th rowspan=2>Jump spin kick degree of rotation</th>
						<td>
							<div class="performance-description">
								<div class="poor">&lt;360&deg;</div>
								<div class="good">360&deg;&ndash;540&deg;</div>
								<div class="very-good">540&deg;&ndash;720&deg;</div>
								<div class="excellent">&gt;720&deg</div>
								<div class="perfect"></div>
							</div>
						</td>
					</tr><tr>
						<td class="button-group">
							<div id="spinning-kick-degree" class="btn-group" data-toggle="buttons">
								<label class="btn btn-danger" ><input type="radio" name="spinning-kick">0.0</label>
								<label class="btn btn-warning"><input type="radio" name="spinning-kick">0.1</label>
								<label class="btn btn-warning"><input type="radio" name="spinning-kick">0.2</label>
								<label class="btn btn-warning"><input type="radio" name="spinning-kick">0.3</label>
								<label class="btn btn-success"><input type="radio" name="spinning-kick">0.4</label>
								<label class="btn btn-success"><input type="radio" name="spinning-kick">0.5</label>
								<label class="btn btn-success"><input type="radio" name="spinning-kick">0.6</label>
								<label class="btn btn-primary"><input type="radio" name="spinning-kick">0.7</label>
								<label class="btn btn-primary"><input type="radio" name="spinning-kick">0.8</label>
								<label class="btn btn-primary"><input type="radio" name="spinning-kick">0.9</label>
								<label class="btn btn-default"><input type="radio" name="spinning-kick">1.0</label>
							</div>
						</td>
					</tr>
				</table>
				<table class="mandatory-foot-technique-4">
					<tr>
						<th rowspan=2>Consecutive sparring kicks</th>
						<td>
							<div class="performance-description">
								<div class="poor">&lt;3 kicks</div>
								<div class="good">3&ndash;5 kicks; good</div>
								<div class="very-good">3&ndash;5 kicks; very good</div>
								<div class="excellent">3&ndash;5 kicks; excellent</div>
								<div class="perfect"></div>
							</div>
						</td>
					</tr><tr>
						<td class="button-group">
							<div id="sparring-kick-performance" class="btn-group" data-toggle="buttons">
								<label class="btn btn-danger" ><input type="radio" name="sparring-kicks">0.0</label>
								<label class="btn btn-warning"><input type="radio" name="sparring-kicks">0.1</label>
								<label class="btn btn-warning"><input type="radio" name="sparring-kicks">0.2</label>
								<label class="btn btn-warning"><input type="radio" name="sparring-kicks">0.3</label>
								<label class="btn btn-success"><input type="radio" name="sparring-kicks">0.4</label>
								<label class="btn btn-success"><input type="radio" name="sparring-kicks">0.5</label>
								<label class="btn btn-success"><input type="radio" name="sparring-kicks">0.6</label>
								<label class="btn btn-primary"><input type="radio" name="sparring-kicks">0.7</label>
								<label class="btn btn-primary"><input type="radio" name="sparring-kicks">0.8</label>
								<label class="btn btn-primary"><input type="radio" name="sparring-kicks">0.9</label>
								<label class="btn btn-default"><input type="radio" name="sparring-kicks">1.0</label>
							</div>
						</td>
					</tr>
				</table>
				<table class="mandatory-foot-technique-5">
					<tr>
						<th rowspan=2>Acrobatic actions</th>
						<td>
							<div class="performance-description">
								<div class="poor" style="font-size: 9pt !important;">No TKD kick</div>
								<div class="good">Low difficulty</div>
								<div class="very-good">Middle difficulty</div>
								<div class="excellent">High difficulty</div>
								<div class="perfect"></div>
							</div>
						</td>
					</tr><tr>
						<td class="button-group">
							<div id="acrobatic-difficulty" class="btn-group" data-toggle="buttons">
								<label class="btn btn-danger" ><input type="radio" name="acrobatic-kicks">0.0</label>
								<label class="btn btn-warning"><input type="radio" name="acrobatic-kicks">0.1</label>
								<label class="btn btn-warning"><input type="radio" name="acrobatic-kicks">0.2</label>
								<label class="btn btn-warning"><input type="radio" name="acrobatic-kicks">0.3</label>
								<label class="btn btn-success"><input type="radio" name="acrobatic-kicks">0.4</label>
								<label class="btn btn-success"><input type="radio" name="acrobatic-kicks">0.5</label>
								<label class="btn btn-success"><input type="radio" name="acrobatic-kicks">0.6</label>
								<label class="btn btn-primary"><input type="radio" name="acrobatic-kicks">0.7</label>
								<label class="btn btn-primary"><input type="radio" name="acrobatic-kicks">0.8</label>
								<label class="btn btn-primary"><input type="radio" name="acrobatic-kicks">0.9</label>
								<label class="btn btn-default"><input type="radio" name="acrobatic-kicks">1.0</label>
							</div>
						</td>
					</tr>
				</table>
				<table class="basic-movements-and-practicality">
					<tr>
						<th>Technique &amp; practicality</th>
						<td class="button-group">
							<div id="basic-movements-and-practicality" class="btn-group" data-toggle="buttons">
								<label class="btn btn-warning"><input type="radio" name="basic-movements">0.0</label>
								<label class="btn btn-warning"><input type="radio" name="basic-movements">0.1</label>
								<label class="btn btn-warning"><input type="radio" name="basic-movements">0.2</label>
								<label class="btn btn-warning"><input type="radio" name="basic-movements">0.3</label>
								<label class="btn btn-warning"><input type="radio" name="basic-movements">0.4</label>
								<label class="btn btn-warning"><input type="radio" name="basic-movements">0.5</label>
								<label class="btn btn-warning"><input type="radio" name="basic-movements">0.6</label>
								<label class="btn btn-warning"><input type="radio" name="basic-movements">0.7</label>
								<label class="btn btn-warning"><input type="radio" name="basic-movements">0.8</label>
								<label class="btn btn-warning"><input type="radio" name="basic-movements">0.9</label>
								<label class="btn btn-warning"><input type="radio" name="basic-movements">1.0</label>
							</div>
						</td>
					</tr>
				</table>

				<div class="technical-component" id="jumping-side-kick-score">
					<div class="component-label">Jumping side kick</div>
					<div class="component-score">0.0</div>
				</div>

				<div class="technical-component" id="jumping-front-kicks-score">
					<div class="component-label">Jumping front kicks</div>
					<div class="component-score">0.0</div>
				</div>

				<div class="technical-component" id="jumping-spin-kick-score">
					<div class="component-label">Jumping spin kick</div>
					<div class="component-score">0.0</div>
				</div>

				<div class="technical-component" id="consecutive-kicks-score">
					<div class="component-label">Consecutive kicks</div>
					<div class="component-score">0.0</div>
				</div>

				<div class="technical-component" id="acrobatic-kick-score">
					<div class="component-label">Acrobatic kick</div>
					<div class="component-score">0.0</div>
				</div>

				<div class="technical-component" id="basic-movements-score">
					<div class="component-label">Basic movements</div>
					<div class="component-score">0.0</div>
				</div>
			</div>

			<div id="presentation">
				<div class="alert alert-default" role="alert"><strong>Presentation</strong>
					<div id="presentation-score" class="pull-right subtotal">0.0</div>
				</div>

				<table>
					<tr>
						<th>Creativity</th>
						<td class="button-group">
							<div id="creativity-score" class="btn-group" data-toggle="buttons">
								<label class="btn btn-success"><input type="radio" name="creativity">0.0</label>
								<label class="btn btn-success"><input type="radio" name="creativity">0.1</label>
								<label class="btn btn-success"><input type="radio" name="creativity">0.2</label>
								<label class="btn btn-success"><input type="radio" name="creativity">0.3</label>
								<label class="btn btn-success"><input type="radio" name="creativity">0.4</label>
								<label class="btn btn-success"><input type="radio" name="creativity">0.5</label>
								<label class="btn btn-success"><input type="radio" name="creativity">0.6</label>
								<label class="btn btn-success"><input type="radio" name="creativity">0.7</label>
								<label class="btn btn-success"><input type="radio" name="creativity">0.8</label>
								<label class="btn btn-success"><input type="radio" name="creativity">0.9</label>
								<label class="btn btn-success"><input type="radio" name="creativity">1.0</label>
							</div>
						</td>
					</tr><tr>
						<td colspan=2>&nbsp;</td>
					</tr><tr>
						<th>Harmony</th>
						<td class="button-group">
							<div id="harmony-score" class="btn-group" data-toggle="buttons">
								<label class="btn btn-success"><input type="radio" name="harmony">0.0</label>
								<label class="btn btn-success"><input type="radio" name="harmony">0.1</label>
								<label class="btn btn-success"><input type="radio" name="harmony">0.2</label>
								<label class="btn btn-success"><input type="radio" name="harmony">0.3</label>
								<label class="btn btn-success"><input type="radio" name="harmony">0.4</label>
								<label class="btn btn-success"><input type="radio" name="harmony">0.5</label>
								<label class="btn btn-success"><input type="radio" name="harmony">0.6</label>
								<label class="btn btn-success"><input type="radio" name="harmony">0.7</label>
								<label class="btn btn-success"><input type="radio" name="harmony">0.8</label>
								<label class="btn btn-success"><input type="radio" name="harmony">0.9</label>
								<label class="btn btn-success"><input type="radio" name="harmony">1.0</label>
							</div>
						</td>
					</tr><tr>
						<td colspan=2>&nbsp;</td>
					</tr><tr>
						<th>Expression of Energy</th>
						<td class="button-group">
							<div id="energy-score" class="btn-group" data-toggle="buttons">
								<label class="btn btn-success"><input type="radio" name="energy">0.0</label>
								<label class="btn btn-success"><input type="radio" name="energy">0.1</label>
								<label class="btn btn-success"><input type="radio" name="energy">0.2</label>
								<label class="btn btn-success"><input type="radio" name="energy">0.3</label>
								<label class="btn btn-success"><input type="radio" name="energy">0.4</label>
								<label class="btn btn-success"><input type="radio" name="energy">0.5</label>
								<label class="btn btn-success"><input type="radio" name="energy">0.6</label>
								<label class="btn btn-success"><input type="radio" name="energy">0.7</label>
								<label class="btn btn-success"><input type="radio" name="energy">0.8</label>
								<label class="btn btn-success"><input type="radio" name="energy">0.9</label>
								<label class="btn btn-success"><input type="radio" name="energy">1.0</label>
							</div>
						</td>
					</tr><tr>
						<td colspan=2>&nbsp;</td>
					</tr><tr>
						<th>Music &amp; Choreography</th>
						<td class="button-group">
							<div id="choreography-score" class="btn-group" data-toggle="buttons">
								<label class="btn btn-success"><input type="radio" name="choreography">0.0</label>
								<label class="btn btn-success"><input type="radio" name="choreography">0.1</label>
								<label class="btn btn-success"><input type="radio" name="choreography">0.2</label>
								<label class="btn btn-success"><input type="radio" name="choreography">0.3</label>
								<label class="btn btn-success"><input type="radio" name="choreography">0.4</label>
								<label class="btn btn-success"><input type="radio" name="choreography">0.5</label>
								<label class="btn btn-success"><input type="radio" name="choreography">0.6</label>
								<label class="btn btn-success"><input type="radio" name="choreography">0.7</label>
								<label class="btn btn-success"><input type="radio" name="choreography">0.8</label>
								<label class="btn btn-success"><input type="radio" name="choreography">0.9</label>
								<label class="btn btn-success"><input type="radio" name="choreography">1.0</label>
							</div>
						</td>
					</tr>
				</table>
			</div>
			<div id="controls">
				<img class="mandatory-foot-technique-icon mandatory-foot-technique-1"       src="../../images/icons/freestyle/jumping-side-kick.png">
				<img class="mandatory-foot-technique-icon mandatory-foot-technique-2"       src="../../images/icons/freestyle/jumping-front-kick.png">
				<img class="mandatory-foot-technique-icon mandatory-foot-technique-3"       src="../../images/icons/freestyle/jumping-spin-kick.png">
				<img class="mandatory-foot-technique-icon mandatory-foot-technique-4"       src="../../images/icons/freestyle/consecutive-kicks.png">
				<img class="mandatory-foot-technique-icon mandatory-foot-technique-5"       src="../../images/icons/freestyle/acrobatic-kick.png">
				<img class="mandatory-foot-technique-icon basic-movements-and-practicality" src="../../images/icons/freestyle/basic-movements.png">

				<div id="major-deductions"></div>
				<div id="stances">
					<div class="mandatory-stances" id="hakdari-seogi"><img src="../../images/icons/freestyle/hakdari-seogi.png"><br>Hakdari Seogi</div>
					<div class="mandatory-stances" id="beom-seogi"><img src="../../images/icons/freestyle/beom-seogi.png"><br>Beom Seogi</div>
					<div class="mandatory-stances" id="dwigubi"><img src="../../images/icons/freestyle/dwigubi.png"><br>Dwigubi</div>
				</div>
				<div id="minor-deductions"></div>
			</div>

		</div>

		<script>
			var score = { technical: {}, presentation: {}, deduction: {} };

			$( '#minor-deductions' ).deductions({ value: 0.1 });
			$( '#major-deductions' ).deductions({ value: 0.3 });

			// ===== MANDATORY STANCES BUTTON BEHAVIOR
			$( '.mandatory-stances' ).find( 'img' ).removeClass( 'done' );
			$( '.mandatory-stances' ).off( 'click' ).click(( b ) => {
				var clicked = $( b.target );
				if( clicked.is( 'img' )) { clicked = clicked.parent(); }
				if( clicked.hasClass( 'done' )) { clicked.removeClass( 'done' ); }
				else                            { clicked.addClass( 'done' ); }
			});

			// ===== TECHNICAL SKILLS BUTTON BEHAVIOR
			var display = { order : {
				'mandatory-foot-technique-1'       : { technique: 'mandatory-foot-technique-2',       score: 'jumping-side-kick-score'   },
				'mandatory-foot-technique-2'       : { technique: 'mandatory-foot-technique-3',       score: 'jumping-front-kicks-score' },
				'mandatory-foot-technique-3'       : { technique: 'mandatory-foot-technique-4',       score: 'jumping-spin-kick-score'   },
				'mandatory-foot-technique-4'       : { technique: 'mandatory-foot-technique-5',       score: 'consecutive-kicks-score'   },
				'mandatory-foot-technique-5'       : { technique: 'basic-movements-and-practicality', score: 'acrobatic-kick-score'      },
				'basic-movements-and-practicality' : { technique: false,                              score: 'basic-movements-score'     },
			}};

			$( '#technical-skills' ).find( 'table' ).hide();
			$( '.mandatory-foot-technique-icon' ).hide();
			$( '.technical-component' ).css({ opacity: 0.2 });
			$( '#presentation' ).hide();

			$( '#start' ).click(( ev ) => { 
				$( '#start' ).hide();
				$( '.mandatory-foot-technique-1' ).fadeIn( 200 );
			});
			$( '#technical-skills' ).find( 'label' ).click(( ev ) => {
				var name    = $( ev.target ).parent().attr( 'id' );
				var value   = parseFloat( $( ev.target ).text());
				var current = $( ev.target ).parents( 'table' ).attr( 'class' );
				var next    = display.order[ current ].technique;
				var results = display.order[ current ].score;

				score.technical[ name ] = value;
				$( '#' + results ).find( '.component-score' ).html( value.toFixed( 1 ) );

				var sum = Object.keys( score.technical ).reduce(( sum, key ) => { sum += score.technical[ key ]; return sum; }, 0.0 );
				$( '#technical-score' ).html( sum.toFixed( 1 ));

				if( next ) { $( '.' + current ).fadeOut( 200, function() { $( '.' + next ).fadeIn( 200 ); }); }
				else       { $( '.' + current ).fadeOut( 200, function() { $( '#controls' ).fadeOut( 200 ); $( '.technical-component' ).animate({ top: '65px' }); $( '#presentation' ).fadeIn( 200 ); }); }
				$( '#' + results ).animate({ opacity: 1.0 });
			});

			// ===== PRESENTATION BUTTON BEHAVIOR
			$( '#presentation' ).find( 'label' ).click(( ev ) => {
				var name  = $( ev.target ).parent().attr( 'id' );
				var value = parseFloat( $( ev.target ).text());

				score.presentation[ name ] = value;

				var sum = Object.keys( score.presentation ).reduce(( sum, key ) => { sum += score.presentation[ key ]; return sum; }, 0.0 );
				$( '#presentation-score' ).html( sum.toFixed( 1 ));
			});

		</script>
	</body>
</html>
