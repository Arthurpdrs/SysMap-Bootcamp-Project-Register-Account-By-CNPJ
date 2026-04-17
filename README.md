# Cadastro de Cliente Corporativo via CNPJ

Fluxo automatizado no Salesforce para cadastro de contas corporativas a partir do CNPJ, com preenchimento automático de dados via integração com a API ReceitaWS.

## Visão Geral

### O que a solução trata

O cadastro manual de clientes corporativos é suscetível a erros de digitação, consome tempo do usuário e frequentemente depende do envio de extensas documentações por parte do cliente ou de pesquisas realizadas pelo funcionário responsável.

O projeto elimina essas barreiras ao automatizar a busca e o preenchimento dos dados a partir do CNPJ, utilizando como fonte a API ReceitaWS — que retorna informações oficiais e atualizadas diretamente da Receita Federal. Isso garante maior confiabilidade e integridade dos dados cadastrados, reduzindo a ocorrência de informações incorretas ou desatualizadas.

### Como funciona

O usuário acessa um Flow guiado, informa o CNPJ da empresa e os dados são buscados e preenchidos automaticamente. Antes de confirmar o cadastro, o usuário pode revisar e editar as informações exibidas. Ao final do processo, é oferecida a opção de cadastrar uma nova empresa sem precisar reiniciar o fluxo.

### Tecnologias envolvidas

- **Salesforce Flow** — interface guiada para o usuário
- **Apex** — integração com a API e lógica de negócio
- **API ReceitaWS** — fonte dos dados corporativos

## Flow

O projeto foi desenvolvido utilizando o Flow, por ser uma ferramenta simples e eficiente, que contribui para a otimização do tempo de desenvolvimento. Considerando que os requisitos não exigem uma interface visual complexa ou alto nível de personalização, o uso Flow permitiu direcionar o foco para a implementação das regras de negócio e da funcionalidade do processo, garantindo maior produtividade e clareza na solução.

O Flow é do tipo **Screen Flow**, acionado através de uma **Quick Action** disponível na página de registros de Account. Ele guia o usuário por um processo estruturado de cadastro ou atualização de clientes corporativos a partir do CNPJ informado.

### Diagrama

![Diagrama do Flow](docs/images/flow-diagram.png)

### Principais Elementos

**Search CNPJ Screen**
Tela inicial do fluxo, onde o usuário informa o CNPJ da empresa que deseja cadastrar. O campo aceita o valor com ou sem máscara.

**Apex Action — Get Company Infos**
Aciona a classe `SearchCompanyAction`, que normaliza o CNPJ recebido, verifica se já existe uma Account cadastrada com esse CNPJ e, caso não exista, realiza o callout à API ReceitaWS para buscar os dados da empresa.

**Decision — Does Account Exists?**
Verifica o valor do atributo `accountAlreadyExists` retornado pela Action e direciona o fluxo para o caminho de criação ou de atualização.

**Decision — Has Error?**
Verifica se o atributo `errorMessage` retornado pela Action está preenchido. Caso haja erro, direciona para a tela de erro. Caso contrário, segue para a tela de confirmação de dados.

**Error Screen**
Exibe a mensagem de erro retornada pela Action, informando o usuário sobre o problema ocorrido durante a consulta.

## Arquitetura e decisõs técnicas

O projeto adota uma arquitetura em camadas baseada no **Service Layer Pattern**, com o objetivo de separar as responsabilidades, manter o código limpo, de fácil manutenção, pouco acoplamento e preparado para evoluções futuras. A vantagem de adotar esse padrão, é que se torna possível trazer evoluções sem a necessidade de modificar muitos trechos de código. Facilita, por exemplo, uma mudança para LWC, sem precisar refazer a lógica de negócio.

### Camadas

As camadas são definidas pelas seguintes classes:

**SearchCompanyAction**
Camada de entrada, exposta ao Flow através de um `@InvocableMethod` chamado `getCompanyInfoByCnpj`. É responsável por receber os dados vindos do Flow, delegá-los à camada de serviço e estruturar a resposta antes de devolvê-la ao Flow. Também centraliza o tratamento de erros, populando o campo `errorMessage` da resposta em caso de falha.
O método `getCompanyInfoByCnpj` é recebe o valor do cnpj para montar a request, ele primeiro verifica se essa conta já está cadastrada no Salesforce através do método interno `accountAlreadyExists`. Se caso existir uma conta é retornado para o Flow, o CNPJ da conta e o atributo indicando que a conta existe.
Esse comportamento foi definido pela necessidade de controlar o padrão de dados consultados afim de evitar conflitos, como duplicidades. Delegar essa consulta para o Apex foi feita com o objetivo de centralizar e padronizar a forma como os dados são buscados e retornados entre o Flow e o banco de dados.

A abordagem de tratamento de erros através do atributo `errorMessage`, visa comunicar melhor ao usuário o comportamento do sistema, lhe entregando mensagens
amigáveis e personalizadas para cada situação melhorando sua experiência de navegação.

A classe `SearchCompanyAction` possui duas classes internas: `Request` e `Response`, responsáveis por estruturar a entrada e a saída da comunicação com o Flow.

O Salesforce exige que métodos `@InvocableMethod` recebam e retornem listas, pois o contrato da plataforma precisa suportar qualquer contexto de execução — incluindo Record-Triggered Flows, que podem processar múltiplos registros simultaneamente. Nesse projeto, por se tratar de um Screen Flow acionado manualmente, a lista sempre conterá um único elemento.
```apex
@InvocableMethod(label='Buscar Empresa por CNPJ' description='Consulta dados na ReceitaWS a partir de um CNPJ')
    public static List<Response> getCompanyInfoByCnpj(List<Request> requests)
```
O uso de classes internas para mapear esses dados, em vez de trabalhar com atributos avulsos dentro de uma lista, facilita o mapeamento e permite que o Flow reconheça e exiba cada atributo de forma individual e organizada.

Essa abordagem foi identificada durante uma pesquisa sobre comunicação entre Flow e Apex, com base na solução apresentada nesta referência: 
https://www.youtube.com/watch?v=6rwsQaqGwig&t=3019s. A estrutura foi analisada, compreendida e adaptada ao contexto do projeto.

**SearchCompanyService**
Camada de negócio, onde fica a lógica principal da aplicação. Seu método principal `getCompanyByCnpj` é composto pela chamada de três métodos internos, cada um com uma responsabilidade específica:

- `validateCnpj` — normaliza e valida os dados de entrada. Esse é o primeiro método a ser executado, para impedir que seja feito algum callout desnecessário.
Caso algum valor de cnpj que seja digitado não se encaixe no padrão de 14 dígitos, o método lança uma AuraHandledException com mensagem personalizada.

- `doCallout` — executa a chamada à API ReceitaWS. Ele utiliza o método `getEndpoint` para definir a url de chamada da API.

- `parseResponse` — valida e mapeia os dados retornados pela API. Esse método ficou responsável por duas validações de resultados vindos da API, no primeiro caso é onde
o status code não é 200 (status ok), assim identificando algum erro na comunicação com a API (bad request por exemplo), e o segundo caso que é quando a API retorna status 200, porém o body da resposta não possui os dados esperados e apresenta um status de `ERROR`. Também são lançadas exceções com mensagens personalizadas.

A escolha por lançar exceções, em caso de caminhos de erro nesses métodos, foi adotada para interromper a execução e evitar inconsistências no fluxo.

**Métodos Auxiliares da classe SearchCompanyService**

**`stripNonDigits`**
Responsável por normalizar a string do CNPJ removendo qualquer caractere não numérico antes da validação. Essa abordagem permite que o usuário informe o CNPJ com ou sem máscara na tela do Flow, além de impedir que valores como texto livre ou espaços em branco cheguem à camada de validação. O método é utilizado internamente pelo `validateCnpj`, sendo parte fundamental na garantia da integridade dos dados de entrada.

**`getEndpoint`**
Responsável por construir a URL de chamada à API. Isolar essa lógica em um método próprio centraliza a definição do endpoint em um único ponto do código, facilitando manutenções futuras e tornando simples uma eventual migração para Named Credentials — recurso do Salesforce para armazenar URLs e credenciais de APIs externas de forma segura e centralizada. Nesse cenário, bastaria alterar uma única linha neste método para que toda a integração passasse a utilizar a Named Credential, sem nenhuma outra modificação no código.

Inicialmente o método `getCompanyByCnpj` foi construído lidando com todas essas lógicas sozinho, porém fazendo uma refatoração foi possível identificar o excesso de
responsabilidades dentro de um só método, portanto foi decidido dividir em métodos menores, isolando as responsabilidades, o que tornou o código mais limpo, com maior
legibilidade e mais fácil de manter. Se precisar modificar alguma regra de validação antes do callout, podemos alterar apenas o `validateCnpj` e manter o restante da mesma forma, por exemplo. 

**SearchCompanyDTO**
Objeto de transferência de dados que estrutura as informações retornadas pela API e as transporta entre as camadas. Conta com o apoio da classe utilitária `AddressFormatter`, responsável por formatar o endereço de forma adequada a partir dos campos retornados pela API. 
Essa formatação do endereço foi pensada para se adequar aos campos de endereço padrão do Salesforce, evitando a criação de mais campos custom e possibilitando o uso do elemento Address no Flow para exibir essas informações. 
Ela diz respeito ao campo billingStreet, que deveria incluir os valores de logradouro, número, complemento e bairro, de acordo com o requisito do projeto.
O campo de CNPJ também é formatado para que seja salvo sem máscara, mantendo uma consistência no banco de dados, assim facilitando buscas e comparações entre registros
que já estão na base do salesforce. A formatação acontece usando o método `stripNonDigits` da classe `SearchCompanyService`.

## Testes

Os testes foram implementados com o objetivo de garantir não apenas a cobertura de código exigida pela plataforma Salesforce, mas também a validação do comportamento esperado em cada cenário — incluindo os caminhos de erro.

### Cobertura

| Classe | Cobertura |
|---|---|
| `SearchCompanyService` | 100% |
| `SearchCompanyServiceTest` | 100% |
| `SearchCompanyAction` | 84% |
| `SearchCompanyActionTest` | 100% |
| **Total** | **94%** |

> O Salesforce exige cobertura mínima de 75% para deploy em produção.

### Mock de Callout

Como o Salesforce não permite chamadas HTTP reais durante a execução de testes, foi implementada a classe `ReceitaWsCalloutMock`, que simula as respostas da API ReceitaWS. Ela oferece dois construtores:

- **Padrão** — simula uma resposta de sucesso com status 200
- **Customizável** — permite definir o status HTTP e o corpo da resposta, utilizado nos cenários de erro

### Cenários cobertos

**`SearchCompanyServiceTest`**

| Cenário | O que valida |
|---|---|
| `testGetCompanyByCnpjSuccess` | Retorno correto do DTO em uma consulta bem sucedida |
| `testGetCompanyByCnpjInvalidCnpj` | Lançamento de exceção para CNPJ inválido |
| `testGetCompanyByCnpjNotFound` | Lançamento de exceção para status HTTP diferente de 200 |
| `testGetCompanyByCnpjCalloutError` | Lançamento de exceção para erro interno da API |

**`SearchCompanyActionTest`**

| Cenário | O que valida |
|---|---|
| `testSuccess` | Retorno correto dos dados da empresa e `errorMessage` nulo |
| `testInvalidCnpj` | Preenchimento do `errorMessage` para CNPJ inválido |
| `testNullRequests` | Retorno de lista vazia para requests nulo |

### Como rodar os testes

**Pelo VS Code:**
1. Abra a paleta de comandos com `Ctrl+Shift+P`
2. Busque por `SFDX: Run All Tests`
3. Os resultados aparecem na aba **Test** no painel lateral

**Pelo Developer Console:**
1. Acesse o Developer Console pela engrenagem ⚙️ no topo do Salesforce
2. Vá em **Test** → **New Run**
3. Selecione as classes de teste e clique em **Run**
4. Os resultados aparecem na aba **Tests** na parte inferior

## Como usar e configurar

### Pré-requisitos

**Campos customizados no objeto Account:**

Antes do deploy, é necessário criar os seguintes campos customizados no objeto Account:

| Campo | API Name | Tipo |
|---|---|---|
| CNPJ | `CNPJ__c` | Text |
| Situação Cadastral | `Status_Cadastral__c` | Text |

Para criar: Setup → Object Manager → Account → Fields & Relationships → New

**Remote Site Settings:**

A URL da API ReceitaWS precisa estar liberada na org. Para configurar:

1. Setup → buscar **Remote Site Settings** → New
2. Preencha:
   - **Remote Site Name:** `ReceitaWS`
   - **Remote Site URL:** `https://receitaws.com.br`
3. Salve

---

### Deploy

Com o projeto aberto no VS Code e a org conectada:

1. Clique com o botão direito na pasta `force-app/main/default`
2. Selecione **SFDX: Deploy Source to Org**
3. Aguarde a confirmação de deploy no terminal

Ou pela paleta de comandos `Ctrl+Shift+P`:
- Busque por `SFDX: Deploy Source to Org`

> Certifique-se de estar autenticado na org correta antes do deploy. Para verificar: `Ctrl+Shift+P` → `SFDX: Authorize an Org`

---

### Configuração do Perfil

Foi criado o perfil **Representante de Vendas**, clonado do perfil **Minimum Access**, com as seguintes permissões no objeto Account:

| Permissão | Habilitada |
|---|---|
| Visualizar | ✅ |
| Criar | ✅ |
| Editar | ✅ |
| Deletar | ❌ |

Todos os campos do objeto Account, incluindo os campos customizados `CNPJ__c` e `Status_Cadastral__c`, estão visíveis e editáveis para esse perfil.

---

### Como usar

1. Acesse qualquer registro de **Account** no Salesforce
2. No topo da página, clique no botão **Cadastrar Cliente Corporativo** na barra de ações
3. Informe o **CNPJ** da empresa — com ou sem máscara
4. O sistema verificará se a empresa já está cadastrada:
   - **Se não existir** — os dados serão buscados automaticamente na API ReceitaWS e preenchidos na tela de confirmação
   - **Se já existir** — os dados do registro existente serão carregados para edição
5. Revise e edite os dados se necessário — o campo CNPJ não é editável
6. Confirme para salvar
7. Ao final, escolha se deseja cadastrar outra empresa ou encerrar o processo