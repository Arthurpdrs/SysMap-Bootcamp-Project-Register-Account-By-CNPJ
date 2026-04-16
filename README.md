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

## Arquitetura e decisõs técnicas

O projeto adota uma arquitetura em camadas baseada no **Service Layer Pattern**, com o objetivo de separar as responsabilidades, manter o código limpo, de fácil manutenção, pouco acoplamento e preparado para evoluções futuras. A vantagem de adotar esse padrão, é que se torna possível trazer evoluções sem a necessidade de modificar muitos trechos de código. Facilita, por exemplo, uma mudança para LWC, sem precisar refazer a lógica de negócio.

### Camadas

As camadas são definidas pelas seguintes classes:

**SearchCompanyAction**
Camada de entrada, exposta ao Flow através de um `@InvocableMethod`. É responsável por receber os dados vindos do Flow, delegá-los à camada de serviço e estruturar a resposta antes de devolvê-la ao Flow. Também centraliza o tratamento de erros, populando o campo `errorMessage` da resposta em caso de falha.

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
- `validateCnpj` — normaliza e valida os dados de entrada
- `doCallout` — executa a chamada à API ReceitaWS
- `parseResponse` — valida e mapeia os dados retornados pela API

**SearchCompanyDTO**
Objeto de transferência de dados que estrutura as informações retornadas pela API e as transporta entre as camadas. Conta com o apoio da classe utilitária `AddressFormatter`, responsável por formatar o endereço de forma adequada a partir dos campos retornados pela API. 
Essa formatação do endereço foi pensada para se adequar aos campos de endereço padrão do Salesforce, evitando a criação de mais campos custom e possibilitando o uso do elemento Address no Flow para exibir essas informações. 
Ela diz respeito ao campo billingStreet, que deveria incluir os valores de logradouro, número, complemento e bairro, de acordo com o requisito do projeto.