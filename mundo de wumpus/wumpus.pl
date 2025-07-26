% ========================================
% MUNDO DE WUMPUS AUTÓNOMO EN PROLOG
% ========================================

:- dynamic(wumpus/2).
:- dynamic(oro/2).
:- dynamic(pozo/2).
:- dynamic(agente/2).
:- dynamic(visitado/2).
:- dynamic(seguro/2).
:- dynamic(peligroso/2).
:- dynamic(brisa_percibida/2).
:- dynamic(hedor_percibido/2).
:- dynamic(tiene_oro/0).
:- dynamic(flecha_disponible/0).
:- dynamic(wumpus_muerto/0).
:- dynamic(juego_terminado/0).

% ========================================
% CONFIGURACIÓN DEL MUNDO
% ========================================

% Tamaño del mundo (4x4)
tamano_mundo(4).

% Configuración inicial del mundo
inicializar_mundo :-
    % Limpiar hechos dinámicos
    retractall(wumpus(_, _)),
    retractall(oro(_, _)),
    retractall(pozo(_, _)),
    retractall(agente(_, _)),
    retractall(visitado(_, _)),
    retractall(seguro(_, _)),
    retractall(peligroso(_, _)),
    retractall(brisa_percibida(_, _)),
    retractall(hedor_percibida(_, _)),
    retractall(tiene_oro),
    retractall(flecha_disponible),
    retractall(wumpus_muerto),
    retractall(juego_terminado),
    
    % Posicionar elementos
    assert(wumpus(3, 1)),
    assert(oro(2, 3)),
    assert(pozo(3, 3)),
    assert(pozo(3, 4)),
    assert(pozo(4, 4)),
    
    % Agente inicia en (1,1)
    assert(agente(1, 1)),
    assert(visitado(1, 1)),
    assert(seguro(1, 1)),
    assert(flecha_disponible).

% ========================================
% PERCEPCIONES
% ========================================

% Percibir brisa (pozo adyacente)
percibir_brisa(X, Y) :-
    (   pozo(X1, Y), X1 is X + 1 ; pozo(X1, Y), X1 is X - 1 ;
        pozo(X, Y1), Y1 is Y + 1 ; pozo(X, Y1), Y1 is Y - 1
    ).

% Percibir hedor (wumpus adyacente)
percibir_hedor(X, Y) :-
    wumpus(WX, WY),
    \+ wumpus_muerto,
    (   (WX is X + 1, WY = Y) ; (WX is X - 1, WY = Y) ;
        (WX = X, WY is Y + 1) ; (WX = X, WY is Y - 1)
    ).

% Percibir brillo (oro en la misma casilla)
percibir_brillo(X, Y) :-
    oro(X, Y).

% ========================================
% MOVIMIENTOS DEL AGENTE
% ========================================

% Verificar si una posición es válida
posicion_valida(X, Y) :-
    tamano_mundo(Max),
    X >= 1, X =< Max,
    Y >= 1, Y =< Max.

% Obtener celdas adyacentes
adyacente(X, Y, X1, Y1) :-
    (   X1 is X + 1, Y1 = Y ;
        X1 is X - 1, Y1 = Y ;
        X1 = X, Y1 is Y + 1 ;
        X1 = X, Y1 is Y - 1
    ),
    posicion_valida(X1, Y1).

% Mover agente
mover_agente(X, Y) :-
    retract(agente(_, _)),
    assert(agente(X, Y)),
    assert(visitado(X, Y)),
    procesar_percepciones(X, Y).

% ========================================
% LÓGICA DEL AGENTE INTELIGENTE
% ========================================

% Procesar percepciones en la posición actual
procesar_percepciones(X, Y) :-
    (   percibir_brisa(X, Y) ->
        assert(brisa_percibida(X, Y)),
        marcar_pozos_posibles(X, Y)
    ;   true
    ),
    (   percibir_hedor(X, Y) ->
        assert(hedor_percibido(X, Y)),
        marcar_wumpus_posible(X, Y)
    ;   true
    ),
    (   percibir_brillo(X, Y) ->
        write('¡ORO ENCONTRADO! Recogiendo...'), nl,
        assert(tiene_oro),
        retract(oro(X, Y))
    ;   true
    ).

% Marcar posibles pozos
marcar_pozos_posibles(X, Y) :-
    forall(
        (adyacente(X, Y, AX, AY), \+ visitado(AX, AY), \+ seguro(AX, AY)),
        assert(peligroso(AX, AY))
    ).

% Marcar posible wumpus
marcar_wumpus_posible(X, Y) :-
    forall(
        (adyacente(X, Y, AX, AY), \+ visitado(AX, AY), \+ seguro(AX, AY)),
        assert(peligroso(AX, AY))
    ).

% Inferir celdas seguras
inferir_seguras :-
    forall(
        (visitado(X, Y), \+ brisa_percibida(X, Y), \+ hedor_percibido(X, Y)),
        marcar_adyacentes_seguras(X, Y)
    ).

marcar_adyacentes_seguras(X, Y) :-
    forall(
        (adyacente(X, Y, AX, AY), \+ peligroso(AX, AY)),
        assert(seguro(AX, AY))
    ).

% ========================================
% ESTRATEGIA DE JUEGO
% ========================================

% Elegir próximo movimiento
elegir_movimiento(X, Y) :-
    agente(CX, CY),
    (   % Prioridad 1: Buscar celda segura no visitada
        encontrar_celda_segura_no_visitada(X, Y)
    ;   % Prioridad 2: Intentar disparar al wumpus si es posible
        intentar_disparar_wumpus(X, Y)
    ;   % Prioridad 3: Retroceder si tiene oro
        (tiene_oro -> retroceder_a_inicio(X, Y) ; fail)
    ;   % Prioridad 4: Explorar celda menos peligrosa
        encontrar_celda_menos_peligrosa(X, Y)
    ).

% Encontrar celda segura no visitada
encontrar_celda_segura_no_visitada(X, Y) :-
    agente(CX, CY),
    adyacente(CX, CY, X, Y),
    seguro(X, Y),
    \+ visitado(X, Y).

% Encontrar celda menos peligrosa (exploración arriesgada)
encontrar_celda_menos_peligrosa(X, Y) :-
    agente(CX, CY),
    adyacente(CX, CY, X, Y),
    \+ visitado(X, Y),
    \+ (pozo(X, Y); (wumpus(X, Y), \+ wumpus_muerto)).

% Retroceder al inicio
retroceder_a_inicio(1, 1).

% Intentar disparar al wumpus
intentar_disparar_wumpus(WX, WY) :-
    flecha_disponible,
    agente(CX, CY),
    wumpus(WX, WY),
    \+ wumpus_muerto,
    % Disparar si está en línea recta
    (   (WX = CX ; WY = CY) ->
        disparar_flecha(WX, WY)
    ;   fail
    ).

% Disparar flecha
disparar_flecha(WX, WY) :-
    agente(CX, CY),
    write('¡DISPARANDO FLECHA AL WUMPUS!'), nl,
    retract(flecha_disponible),
    (   (WX = CX ; WY = CY) ->
        (write('¡WUMPUS ELIMINADO!'), nl,
         assert(wumpus_muerto))
    ;   write('Flecha falló...'), nl
    ).

% ========================================
% VISUALIZACIÓN
% ========================================

% Mostrar el mundo
mostrar_mundo :-
    tamano_mundo(Max),
    nl,
    write('=== MUNDO DE WUMPUS ==='), nl,
    write('A=Agente, W=Wumpus, O=Oro, P=Pozo'), nl,
    write('v=Visitado, ?=Peligroso, !=Seguro'), nl, nl,
    mostrar_fila(Max, Max).

mostrar_fila(Y, Max) :-
    Y > 0,
    mostrar_columna(1, Y, Max),
    nl,
    Y1 is Y - 1,
    mostrar_fila(Y1, Max).
mostrar_fila(0, _).

mostrar_columna(X, Y, Max) :-
    X =< Max,
    write('['),
    mostrar_contenido_celda(X, Y),
    write(']'),
    X1 is X + 1,
    mostrar_columna(X1, Y, Max).
mostrar_columna(X, _, Max) :- X > Max.

mostrar_contenido_celda(X, Y) :-
    (   agente(X, Y) -> write('A')
    ;   (wumpus(X, Y), \+ wumpus_muerto) -> write('W')
    ;   oro(X, Y) -> write('O')
    ;   pozo(X, Y) -> write('P')
    ;   visitado(X, Y) -> write('v')
    ;   peligroso(X, Y) -> write('?')
    ;   seguro(X, Y) -> write('!')
    ;   write(' ')
    ).

% Mostrar estado
mostrar_estado :-
    agente(X, Y),
    format('Agente en: (~w,~w)~n', [X, Y]),
    (tiene_oro -> write('Tiene oro: SÍ') ; write('Tiene oro: NO')), nl,
    (flecha_disponible -> write('Flecha: SÍ') ; write('Flecha: NO')), nl,
    (wumpus_muerto -> write('Wumpus: MUERTO') ; write('Wumpus: VIVO')), nl,
    
    % Mostrar percepciones
    (   percibir_brisa(X, Y) -> write('Percibe: BRISA ') ; true),
    (   percibir_hedor(X, Y) -> write('Percibe: HEDOR ') ; true),
    (   percibir_brillo(X, Y) -> write('Percibe: BRILLO ') ; true),
    nl, nl.

% ========================================
% BUCLE PRINCIPAL DEL JUEGO
% ========================================

% Iniciar juego
jugar :-
    inicializar_mundo,
    write('=== INICIANDO JUEGO DE WUMPUS AUTÓNOMO ==='), nl,
    bucle_juego.

% Bucle principal
bucle_juego :-
    \+ juego_terminado,
    mostrar_mundo,
    mostrar_estado,
    
    % Esperar entrada del usuario para continuar
    write('Presione Enter para continuar...'), nl,
    read_line_to_codes(user_input, _),
    
    % Procesar turno
    agente(CX, CY),
    procesar_percepciones(CX, CY),
    inferir_seguras,
    
    % Verificar condiciones de victoria/derrota
    (   (tiene_oro, agente(1, 1)) ->
        (write('¡VICTORIA! Agente regresó con el oro.'), nl,
         assert(juego_terminado))
    ;   (agente(X, Y), (pozo(X, Y); (wumpus(X, Y), \+ wumpus_muerto))) ->
        (write('¡DERROTA! El agente ha muerto.'), nl,
         assert(juego_terminado))
    ;   % Elegir y ejecutar próximo movimiento
        (   elegir_movimiento(NX, NY) ->
            (format('Moviendo a (~w,~w)~n', [NX, NY]),
             mover_agente(NX, NY))
        ;   (write('No hay movimientos seguros disponibles.'), nl,
             assert(juego_terminado))
        )
    ),
    
    % Continuar bucle
    bucle_juego.

bucle_juego :-
    juego_terminado,
    write('=== FIN DEL JUEGO ==='), nl.

% ========================================
% PREDICADO PRINCIPAL
% ========================================

% Para iniciar el juego, usar: ?- jugar.