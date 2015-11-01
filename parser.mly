%{ open Ast %}

%token SEMI LPAREN RPAREN LBRACE RBRACE COMMA DOT
%token PLUS MINUS TIMES DIVIDE ASSIGN MOD
%token AND OR NOT
%token EQ NEQ LT LEQ GT GEQ
%token RETURN IF ELSE FOR WHILE INT
%token <int> INTLITERAL
%token <char> CHARLITERAL
%token <string> STRLITERAL
%token <string> ID
%token EOF
%token IN
%token BREAK CONTINUE
%token ELIF
%token TRUE FALSE NONE
%token STR BOOL VOID LIST GROUP
%token ASSERT
%token REMOVE PLACE
%token SETUP TURNS

%nonassoc NOELSE
%nonassoc ELSE
%right ASSIGN
%right DOT
%left OR
%left AND
%left EQ NEQ
%left LT GT LEQ GEQ
%left PLUS MINUS MOD
%left TIMES DIVIDE

%start program
%type <Ast.program> program

%%

program:
  decls EOF { $1 }

decls:
   /* nothing */ { [], [] }
 | decls vdecl { ($2 :: fst $1), snd $1 }
 | decls fdecl { fst $1, ($2 :: snd $1) }

fdecl:
   ID LPAREN formals_opt RPAREN LBRACE vdecl_list stmt_list RBRACE
     { { fname = $1;
     formals = $3;
     locals = List.rev $6;
     body = List.rev $7 } }

formals_opt:
    /* nothing */ { [] }
  | formal_list   { List.rev $1 }

formal_list:
    ID                   { [$1] }
  | formal_list COMMA ID { $3 :: $1 }

vdecl_list:
    /* nothing */    { [] }
  | vdecl_list vdecl { $2 :: $1 }

vdecl:
   INT ID SEMI { $2 }

stmt_list:
    /* nothing */  { [] }
  | stmt_list stmt { $2 :: $1 }

stmt:
    expr SEMI { Expr($1) }
  | RETURN expr SEMI { Return($2) }
  | LBRACE stmt_list RBRACE { Block(List.rev $2) }
  | IF LPAREN expr RPAREN LBRACE stmt RBRACE %prec NOELSE
     { If($3, $6, Block([])) }
  | IF LPAREN expr RPAREN LBRACE stmt RBRACE ELIF LBRACE stmt RBRACE
     { If($3, $6, $10) }
  | IF LPAREN expr RPAREN LBRACE stmt RBRACE ELSE LBRACE stmt RBRACE
     { If($3, $6, $10) }
  | FOR LPAREN expr IN LBRACE expr_list RBRACE RPAREN LBRACE stmt RBRACE
     { For($3, $6, $10) }
  | WHILE LPAREN expr RPAREN LBRACE stmt RBRACE
     { While($3, $6) }
  | BREAK SEMI    { Break}
  | CONTINUE SEMI { Continue }

expr:
    INTLITERAL       { IntLiteral($1) }
  | STRLITERAL       { StrLiteral($1) }
  | ID               { Id($1) }
  /* | expr DOT expr    {}  we don't have calls implemented yet, how should we do this */
  | expr PLUS   expr { Binop($1, Add,   $3) }
  | expr MINUS  expr { Binop($1, Sub,   $3) }
  | expr TIMES  expr { Binop($1, Mult,  $3) }
  | expr DIVIDE expr { Binop($1, Div,   $3) }
  | expr MOD    expr { Binop($1, Mod,   $3) }
  | expr EQ     expr { Binop($1, Equal, $3) }
  | expr NEQ    expr { Binop($1, Neq,   $3) }
  | expr LT     expr { Binop($1, Less,  $3) }
  | expr LEQ    expr { Binop($1, Leq,   $3) }
  | expr GT     expr { Binop($1, Greater,  $3) }
  | expr GEQ    expr { Binop($1, Geq,   $3) }
  | expr AND    expr { Binop($1, And,   $3) }
  | expr OR    expr  { Binop($1, Or,    $3) }
  | ID ASSIGN expr   { Assign($1, $3) }
  | ID LPAREN actuals_opt RPAREN { Call($1, $3) }
  | LPAREN expr RPAREN { $2 }

expr_list:
    expr                 { [$1] }
  | expr_list COMMA expr { $3 :: $1 }

actuals_opt:
    /* nothing */ { [] }
  | actuals_list  { List.rev $1 }

actuals_list:
    expr                    { [$1] }
  | actuals_list COMMA expr { $3 :: $1 }
