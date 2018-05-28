


# Overview Weaver.Model

## 1. Intro
`Weaver.Model` is a concept that only exists SDK (client) side. It is a filtered way to interact with the *schemaless* graph data inside a Weaver Project.
- If it is used to create data it will function like a schema by validating the input.
- If used for reading from a mixed project data it will only show the nodes, attributes and relations the model describes and leave the others invisible.

### Definition

A model is defined in a `.yml` file:
```yaml
name: some-model
version: 1.0.0

classes:

  Thing
```

Which can be visualised in a UML-like diagram:

![Alt text](https://g.gravizo.com/source/svg/diagram_1?https%3A%2F%2Fraw.githubusercontent.com%2Fweaverplatform%2Fweaver-sdk-js%2Fmodel-ideas%2Fmodels.md)
<details>
<summary></summary>
diagram_1
  digraph A {
    rankdir=LR;
    subgraph cluster_0 {
      label="some-model";
      rankdir=LR;
      node [shape = ellipse];
      Thing
    }
  }
diagram_1
</details>



## 2. Concepts

Concepts in the model are `classes`, `relations` and `attributes`. 
```yaml
name: some-model
version: 1.0.0

classes:

  Thing:

  Person:
    attributes:
      name:
        datatype: string
    relations:
      owns:
        range: Thing
```

![Alt text](https://g.gravizo.com/source/svg/diagram_2?https%3A%2F%2Fraw.githubusercontent.com%2Fweaverplatform%2Fweaver-sdk-js%2Fmodel-ideas%2Fmodels.md)
<details>
<summary></summary>
diagram_2
  digraph B {
    rankdir=LR;
    subgraph cluster_0 {
      label="some-model";
      rankdir=LR;
      node [shape = ellipse];
      Person
      Thing
      name [label="_string_"; shape = box]
      Person -> name [label=name; arrowtail=diamond; arrowhead=vee; dir=both];
      Person -> Thing [label=owns; arrowtail=diamond; arrowhead=vee; dir=both];
    }
  }
diagram_2
</details>

### Meta relations

Relations can also be references as classes. However they should not be instantiated directly. This is prevented by the flag `abstract: true`.
```yaml
name: some-model
version: 1.0.0

classes:

  Thing:

  Person:
    attributes:
      name:
        datatype: string
    relations:
      owns:
        range: Thing

  owns:
    abstract: true
    attributes:
      since: 
        datatype: datetime
```

![Alt text](https://g.gravizo.com/source/svg/diagram_3?https%3A%2F%2Fraw.githubusercontent.com%2Fweaverplatform%2Fweaver-sdk-js%2Fmodel-ideas%2Fmodels.md)
<details>
<summary></summary>
diagram_3
  digraph C {
    rankdir=LR;
    subgraph cluster_0 {
      label="some-model";
      rankdir=LR;
      node [shape = ellipse];
      Person
      Thing
      name [label="_string_"; shape = box]
      since [label="_datetime_"; shape = box]
      owns [label="owns"; shape = diamond]
      Person -> name [label=name; arrowtail=diamond; arrowhead=vee; dir=both];
      Person -> owns [label=""; arrowtail=diamond; arrowhead=none; dir=both];
      owns -> Thing [label=""; arrowhead=vee];
      owns -> since [label=since; arrowtail=diamond; arrowhead=vee; dir=both];
      {rank=same owns name since};
      since -> owns  [style="invis"];
    }
  }
diagram_3
</details>

### Model keys

Sometimes the relationship names are a long or complex. It is possible to use a simplified key in the model using the `modelKey`. The following model is equivalent with model above:

```yaml
name: some-model
version: 1.0.0

classes:

  Thing:

  Person:
    attributes:
      hasReferenceString:
        modelKey: name
        datatype: string
    relations:
      isInInheritanceGroupOf:
        modelKey: owns
        range: Thing
```

## 3. Inclusion and inheritence
![Alt text](https://g.gravizo.com/source/svg/diagram_4?https%3A%2F%2Fraw.githubusercontent.com%2Fweaverplatform%2Fweaver-sdk-js%2Fmodel-ideas%2Fmodels.md)
<details>
<summary></summary>
diagram_4
  digraph D {
    rankdir=LR;
    subgraph cluster_0 {
      label="fruit-model";
      rankdir=LR;
      node [shape = diamond];
      eaterOwns [label="owns"];
      node [shape = box];
      Eater -> Fruit [label=eats; arrowtail=diamond; arrowhead=vee; dir=both];
      Fruit -> Color [label=hasColor; arrowtail=diamond; arrowhead=vee; dir=both];
      Eater -> eaterOwns [label=""; arrowtail=diamond; arrowhead=none; dir=both];
      eaterOwns -> Fruit [label=owns; arrowhead=vee];
      eaterOwns -> Date [label=since; arrowtail=diamond; arrowhead=vee; dir=both];
    }
  }
diagram_4
</details>

```yaml
name: fruit-model
version: 1.0.0

classes:                                                      # domain                 # range

  Fruit:                       # fruit-model:Fruit
    relations:
      hasColor:                # fruit-model:hasColor         fruit-model:Fruit        fruit-model:Color
        range: Color           # fruit-model:Color

  Apple:
    super: Fruit

  Eater:                       # fruit-model:Eater
    relations:
      owns:                    # fruit-model:owns             fruit-model:Eater        fruit-model:Fruit
        range: Fruit 
      eats:                    # fruit-model:eats             fruit-model:Eater        fruit-model:Fruit
        range: Fruit 

  owns:                        # fruit-model:owns
    abstract: true
    relations:
      since:                   # fruit-model:since            fruit-model:owns         fruit-model:Date
        range: Date            # fruit-model:Date
  
  Date:                        # fruit-model:Date

  Color:                       # fruit-model:Color
```


Inherit from included model:
![Alt text](https://g.gravizo.com/source/svg/diagram_5?https%3A%2F%2Fraw.githubusercontent.com%2Fweaverplatform%2Fweaver-sdk-js%2Fmodel-ideas%2Fmodels.md)
<details>
<summary></summary>
diagram_5
  digraph E {
    rankdir=LR;
    subgraph cluster_0 {
      label="fruit-model";
      eaterOwns [shape = diamond; label="owns"];
      node [shape = box];
      Eater; Fruit; Color; Fruit; Date
    }
    subgraph cluster_1 {
      label="monkey-model";
      node [shape = box];
      Monkey; Tree; Banana; monkeyOwns [shape = diamond; label="owns"];
    }
    Eater -> Monkey [abel=""; arrowtail=onormal; arrowhead=diamond; dir=both]
    Fruit -> Banana [label=""; arrowtail=onormal; arrowhead=diamond; dir=both; constraint=false]
    eaterOwns -> monkeyOwns [abel=""; arrowtail=onormal; arrowhead=diamond; dir=both]
    Monkey -> Fruit [label=eats; style=dotted; arrowtail=diamond; arrowhead=vee; dir=both];
    Monkey -> Tree [label="ownsTree"; arrowtail=diamond; arrowhead=vee; dir=both];
    Monkey -> monkeyOwns [label=""; arrowtail=diamond; arrowhead=none; dir=both];
    monkeyOwns -> Banana [label=""; arrowhead=vee];
    monkeyOwns -> Date [label=since; style=dotted; arrowtail=diamond; arrowhead=vee; dir=both; constraint=false];
    monkeyOwns -> Date [label=till; arrowtail=diamond; arrowhead=vee; dir=both; constraint=false];
    Eater -> Fruit [label=eats; arrowtail=diamond; arrowhead=vee; dir=both];
    Fruit -> Color [label=hasColor; arrowtail=diamond; arrowhead=vee; dir=both];
    Eater -> eaterOwns [label=""; arrowtail=diamond; arrowhead=none; dir=both];
    eaterOwns -> Fruit [label=owns; arrowhead=vee];
    eaterOwns -> Date [label=since; arrowtail=diamond; arrowhead=vee; dir=both];
  }
diagram_5
</details>

```yaml
name: monkey-model
version: 1.0.0

includes:
  fm:
    name: fruit-model
    version: 1.0.0

classes:                                                      # domain                 # range

  Monkey:                      # monkey-model:Monkey
    super: fm.Eater            # fruit-model:Eater
    relations:
      ownsTree:                # monkey-model:ownsTree        monkey-model:Monkey      monkey-model:Tree
        range: Tree            # monkey-model:Tree
        modelKey: owns
        card: [0, 1]
      owns:                    # monkey-model:owns            monkey-model:Monkey      monkey-model:Banana
        range: Banana          # monkey-model:Banana
        modelKey: owns
        card: [0, n]

  owns:                        # monkey-model:owns
    super: fm.owns             # fruit-model:owns
    abstract: true
    relations:
      till:                    # monkey-model:till            monkey-model:owns        fruit-model:Date
        range: fm.Date         # fruit-model:Date

  Banana:                      # monkey-model:Banana
    super: fm.Fruit            # fruit-model:Fruit

  Tree:                        # monkey-model:Tree

  Color:                       # monkey-model:Color

```

