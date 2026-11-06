# 🚀 Duna Kids (Flutter / Dart)

Aplicativo Mobile Multiplataforma (**iOS & Android**) com identidade visual corporativa moderna inspirada na linguagem de design do **Angular v22**, utilizando a sofisticada paleta **Azure Blue** e integrado ao backend **Supabase**.

---

## 🏫 1. Gestão de Turmas / Salas (`/turmas`)

Tela para visualização e gerenciamento de salas infantis ([`classrooms_screen.dart`](file:///C:/Users/suportesecid/.gemini/antigravity/scratch/azure_auth_app/lib/features/classrooms/screens/classrooms_screen.dart)):

* **Campos da Turma**:
  * **Nome da Turma** (ex: *Berçário*, *Maternal*, *Juniores*).
  * **Capacidade Máxima de Alunos** (vagas disponíveis).
  * **Faixa Etária / Idade da Turma** (ex: *0 a 2 anos*, *3 a 5 anos*).
  * **Cor de Identificação**: Paleta moderna para diferenciação visual rápida.
* **Regra de Status da Turma**:
  * A turma **só fica com status Ativa/Aberta** caso esteja vinculada a um evento ativo no momento (`active_classroom_ids` do evento).
  * Se não houver evento ativo associado, exibe status **Fechada**.
* **Controle de Acesso por Papel**:
  * **Apenas Administradores (`isAdmin`)**: Podem criar, editar ou excluir turmas (`ClassroomFormDialog`).
  * **Professores (`isTeacher`) e Administradores (`isAdmin`)**: Podem tocar na sala aberta para visualizar as crianças dentro dela.

---

## 📅 2. Gestão de Eventos & Abertura de Salas (`/eventos`)

Tela para planejamento e ativação de eventos da igreja ([`events_screen.dart`](file:///C:/Users/suportesecid/.gemini/antigravity/scratch/azure_auth_app/lib/features/events/screens/events_screen.dart)):

* **Campos do Evento**:
  * **Título do Evento** (ex: *Culto de Domingo - Manhã*, *Culto de Jovens*).
  * **Data Início e Data Fim**.
  * **Horário Início e Horário Fim** (ex: *09:00 às 11:30*).
  * **Seleção de Salas Abertas**: O administrador seleciona quais turmas específicas serão ativadas/abertas durante a vigência do evento.
  * **Switch de Ativação**: Permite abrir ou pausar o evento a qualquer instante.
* **Permissão**:
  * Criação, edição e exclusão de eventos restrita a **Administradores**.

---

## 🎒 3. Sala ao Vivo: Visualização das Crianças (`ClassroomDetailScreen`)

Tela de acompanhamento presencial das crianças presentes na turma ([`classroom_detail_screen.dart`](file:///C:/Users/suportesecid/.gemini/antigravity/scratch/azure_auth_app/lib/features/classrooms/screens/classroom_detail_screen.dart)):

* **Acesso Restrito**: Exclusivo para **Professores e Administradores**.
* **Informações em Tempo Real**:
  * Lotação da sala (*ex: 8 / 15 alunos*).
  * Lista de crianças presentes com foto, nome completo, idade e horário de entrada (check-in).
  * **Destaque Legal Lei nº 13.146/2015**: Alerta visual proeminente com ícone de acessibilidade para crianças com necessidades de inclusão.
  * Observações médicas, alimentares e alergias em destaque.
  * Botão para registrar a saída da criança (*Check-out*).

---

## 📁 Estrutura de Arquivos

```
azure_auth_app/
├── assets/
│   └── images/
│       └── logo.jpg                    # Logo oficial do aplicativo
├── lib/
│   ├── core/
│   │   ├── config/
│   │   │   └── supabase_config.dart    # Configurações de URL e Chaves Supabase
│   │   ├── services/
│   │   │   └── supabase_service.dart   # Camada Supabase: Auth, Perfis, Crianças, Turmas e Eventos
│   │   ├── theme/
│   │   │   ├── app_colors.dart         # Paleta de cores Azure Blue & Slate
│   │   │   ├── app_typography.dart     # Tipografia Inter
│   │   └── widgets/
│   │       ├── azure_button.dart       # Botão primário, secundário e outline
│   │       ├── azure_text_field.dart   # Input moderno com toggle de senha
│   │       └── azure_card.dart         # Container com estética Angular moderna
│   ├── features/
│   │   ├── auth/
│   │   │   └── screens/
│   │   │       ├── login_screen.dart           # Login conectado ao Supabase
│   │   │       ├── register_screen.dart        # Cadastro de novos usuários
│   │   │       └── forgot_password_dialog.dart # Modal de Recuperação de Senha
│   │   ├── children/
│   │   │   ├── models/
│   │   │   │   └── child_model.dart            # Modelo de dados da criança (Lei 13.146/2015)
│   │   │   └── widgets/
│   │   │       └── child_form_dialog.dart      # Modal moderno para cadastrar/editar crianças
│   │   ├── classrooms/
│   │   │   ├── models/
│   │   │   │   ├── classroom_model.dart        # Modelo de dados da turma
│   │   │   │   └── attendance_model.dart       # Modelo de presença e check-in
│   │   │   ├── screens/
│   │   │   │   ├── classrooms_screen.dart      # Gestão de Turmas (Status dinâmico)
│   │   │   │   └── classroom_detail_screen.dart# Crianças na sala (Professores e Admins)
│   │   │   └── widgets/
│   │   │       └── classroom_form_dialog.dart  # Modal de cadastro de turma (Admin)
│   │   ├── events/
│   │   │   ├── models/
│   │   │   │   └── church_event_model.dart     # Modelo de evento e abertura de salas
│   │   │   ├── screens/
│   │   │   │   └── events_screen.dart          # Gestão de Eventos
│   │   │   └── widgets/
│   │   │       └── event_form_dialog.dart      # Modal de cadastro de evento (Admin)
│   │   └── profile/
│   │       ├── models/
│   │       │   └── user_profile_model.dart     # Modelo de dados e cálculo de múltiplos papéis
│   │       └── screens/
│   │           └── meus_dados_screen.dart      # Tela Meus Dados com navegação integrada
│   └── main.dart                               # Rotas e Inicialização
└── test/
    └── widget_test.dart                        # Testes automatizados de todas as telas
```

---

## 📲 Como Executar

```bash
cd C:\Users\suportesecid\.gemini\antigravity\scratch\azure_auth_app

# Executar testes
flutter test

# Rodar no Navegador (Chrome)
flutter run -d chrome

# Rodar no Android
flutter run -d android

# Rodar no iOS
flutter run -d ios
```
