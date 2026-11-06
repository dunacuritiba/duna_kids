import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duna_kids/main.dart';
import 'package:duna_kids/features/checkin/screens/checkin_screen.dart';
import 'package:duna_kids/features/classrooms/screens/classrooms_screen.dart';
import 'package:duna_kids/features/events/screens/events_screen.dart';
import 'package:duna_kids/features/profile/screens/meus_dados_screen.dart';

void main() {
  testWidgets('Valida renderizacao da tela de Login e navegacao para Cadastro', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DunaKidsApp());
    await tester.pumpAndSettle();

    // 1. Verifica elementos principais do login
    expect(find.text('Bem-vindo de volta'), findsOneWidget);
    expect(find.text('Acessar Plataforma'), findsOneWidget);
    expect(find.text('Lembrar de mim'), findsOneWidget);
    expect(find.text('Esqueceu a senha?'), findsOneWidget);

    final signupFinder = find.text('Criar conta agora');
    expect(signupFinder, findsOneWidget);

    // 2. Toca no link para criar nova conta
    await tester.tap(signupFinder);
    await tester.pumpAndSettle();

    // 3. Verifica se navegou para a tela de cadastro
    expect(find.text('Criar Novo Acesso'), findsOneWidget);
    expect(find.text('Finalizar Cadastro'), findsOneWidget);
    expect(find.text('Nome Completo'), findsOneWidget);
    expect(find.text('Concordo com os Termos de Serviço e Política de Privacidade.'), findsOneWidget);

    // 4. Volta para a tela de login
    await tester.tap(find.text('Fazer Login'));
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo de volta'), findsOneWidget);
  });

  testWidgets('Valida elementos da tela Meus Dados e niveis de acesso', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MeusDadosScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Meus Dados'), findsOneWidget);
    expect(find.text('Dados Pessoais'), findsOneWidget);
    expect(find.text('Papel Familiar / Responsável'), findsOneWidget);
    expect(find.text('Responsável'), findsWidgets);
    expect(find.text('Crianças Cadastradas'), findsOneWidget);
    expect(find.text('Nome Completo'), findsOneWidget);
    expect(find.text('Número de Contato / WhatsApp'), findsOneWidget);
    expect(find.text('Data de Nascimento'), findsWidgets);
    expect(find.text('Salvar Alterações'), findsOneWidget);
  });

  testWidgets('Valida Navbar moderno e Menu Dropdown com as views', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MeusDadosScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verifica presença do botão Menu no navbar
    final menuButton = find.text('Menu');
    expect(menuButton, findsOneWidget);

    // Toca no botão Menu
    await tester.tap(menuButton);
    await tester.pumpAndSettle();

    // Verifica que o dropdown modal abriu com as opções de views para o responsável
    expect(find.text('MÓDULOS DO SISTEMA'), findsOneWidget);
    expect(find.text('Meus Dados'), findsWidgets);
    expect(find.text('Check-in Kids'), findsWidgets);
    expect(find.text('Encerrar Sessão'), findsOneWidget);
  });

  testWidgets('Valida renderizacao da tela Gestao de Turmas com Navbar', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ClassroomsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gestão de Turmas'), findsOneWidget);
    expect(find.text('Visão Geral das Salas'), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
  });

  testWidgets('Valida renderizacao da tela Gestao de Eventos com Navbar', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: EventsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gestão de Eventos'), findsOneWidget);
    expect(find.text('Eventos e Abertura de Salas'), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
  });

  testWidgets('Valida renderizacao da tela de Check-in Kids com Navbar', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: CheckinScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Check-in Kids'), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
  });
}
