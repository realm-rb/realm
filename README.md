# Realm

Domain layer framework following Domain-driven/CQRS design principles.

[![Build status](https://badge.buildkite.com/346cce75f6c31e0a41bb98b198e85eb6b722243624459fad9c.svg)](https://buildkite.com/reevoo/realm)

## Service layers

We follow the standard MVC design pattern of Rails but giving the model layer more structure and guidance regarding where
to put your code. The model is split into domain layer (using our [Realm](https://github.com/reevoo/smart-mono/tree/master/gems/realm) library)
and persistence layer (using [ROM](https://rom-rb.org/) library). The individual components are explained in the following section.

![Service layers](https://confluence-connect.gliffy.net/embed/image/d02d04b1-5e40-415f-b7ba-3a631efa9bf3.png?utm_medium=live&utm_source=custom)

Advanced components are shown in lighter color, those will be needed only later on as the service domain logic grows.

## Model layer components

![Service external components](https://confluence-connect.gliffy.net/embed/image/c593fcc2-304e-47c3-8e3c-b0cc09e0ed54.png?utm_medium=live&utm_source=custom)

Each service has one **domain** module which consists of multiple [**aggregate**](https://martinfowler.com/bliki/DDD_Aggregate.html) modules.
Aggregate is a cluster of domain objects that can be treated as a single unit. The only way for outer world to communicate
with aggregate is by **queries** and **commands**. Query exposes aggregate's internal state and command changes it.
The state of an aggregate is represented by tree of **entities** with one being the aggregate root and zero or more dependent
entities with *belongs_to* relation to the root entity. The state of an aggregate (entity tree) is persisted
and retrieved by **repository**. There is generally one repository per aggregate unless we split the read/write
(query/command) persistence model for that particular domain. The repository uses **relations** to access the database
tables. Each relation class represents one table.


## Where to put my code as it grows?

TODO
