# NOVA Management — ESX Legacy

Resource de administração para criar empregos ESX e gerir fechaduras simples no mundo.

## Dependências
- `es_extended` (ESX Legacy)
- `oxmysql`

## Instalação
1. Copia a pasta `nova_management` para `resources/[local]/`.
2. Confirma que `oxmysql` e `es_extended` iniciam antes deste resource.
3. No `server.cfg`, adiciona:
   ```
   ensure oxmysql
   ensure es_extended
   ensure nova_management
   ```
4. Importa `install.sql` na base de dados (o resource também cria a tabela automaticamente).
5. Em `config.lua`, ajusta `Config.AllowedGroups` aos grupos de administrador usados no teu servidor.
6. Reinicia o servidor.

## Utilização
- No jogo, escreve `/novamenu`.
- Separador **Empregos**: cria um job e adiciona ranks/salários.
- Separador **Doorlocks**: aponta para uma porta, escolhe “Adicionar porta” e guarda. A posição/modelo são capturados à tua frente.
- Para abrir/fechar, aproxima-te e prime **E**.

## Notas importantes
- Este é um sistema de fechaduras básico para portas que são objetos individuais do mapa. Não substitui recursos avançados de doorlock.
- A porta é localizada pelo modelo e coordenadas capturados. Portas duplas, portas com dois objetos, portas de interiores instanciados e portas que exigem natives especiais podem precisar de suporte adicional.
- Jobs novos são inseridos em `jobs` e `job_grades`. O ESX pode exigir refresh/restart para disponibilizar o job em `xPlayer.setJob`; reinicia o servidor após criar jobs se não aparecerem nos menus.
- O campo de jobs vazio numa fechadura significa acesso a todos. Para restringir, escreve nomes separados por vírgulas, por exemplo `police, ambulance`.
- A autorização é sempre validada no servidor; não confies apenas na interface.
- Antes de usar em produção, testa num servidor de desenvolvimento e faz backup da base de dados.

## Atualização v1.0.2
- Lista de grades por emprego, com edição, adição e remoção.
- Atualização do cache de empregos ESX após criar, editar ou apagar jobs, para permitir usar `/setjob` sem reiniciar.

## Atualização v1.0.1
- Interface redesenhada com navegação lateral e cartões de resumo.
- Confirmação de eliminação própria na NUI (não utiliza `window.confirm`, que pode ser bloqueado pelo CEF/NUI).
- Eliminação de empregos com validação e transação SQL.
