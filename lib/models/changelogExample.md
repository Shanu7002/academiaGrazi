# This is a guide to create a changelog.xml to your model

After a change in any something_model.dart, you have to update the something_model_changelog.xml.

**IMPORTANT** ⚠️ NOTE THAT YOU DO NOT CHANGE THE PREVIOUS CHANGELG, YOU ADD A NEW ONE WITH SAME STRUCT, IT'S A VERSION CONTROL IDEA ⚠️

In this scenario you gonna have 3 paths, new model, major change or minor change.

What caracterizes a major or minor change?

- A major change its a breakchange change. EX: modifying existing data types, removing fields, or fundamentally altering the model architecture.
- A minor change its a change that shouldnt break anything. EX: Adding new optional fields, adding class methods (e.g., JSON parsers), or correcting typos.

## New Model

To create a new changelog.xml, you can simple paste this and change the informations to the real ones.

```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <changelog>
        <model>
            <version>version</version>
            <owner>who changed this</owner>
            <description>Initial model creation</description>
            <actualModel>
                A Json trying to recreate the model in firebase ex:
                    user = {
                        id: --gerado automaticamente  28-character strings (Base62)
                        name: string
                        email: string
                        type: UserType enum
                        createdAt: string (iso8601) - horario do dispositivo para nao se preocupar com ztimestamp convertion
                    }
            </actualModel>
        </model>
    </changelog>
```

## Major Change

A Major change requires you to update the version to the next Int number, you as owner and new model.

This change log

```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <changelog>
        <model>
            <version>1.0</version>
            <owner>XXX</owner>
            <description>Initial model creation</description>
            <actualModel>
                A Json trying to recreate the model in firebase ex:
                    user = {
                        id: --gerado automaticamente  28-character strings (Base62)
                        name: string
                        email: string
                        type: UserType enum
                        createdAt: string (iso8601) - horario do dispositivo para nao se preocupar com ztimestamp convertion
                    }
            </actualModel>
        </model>
    </changelog>
```

Gonna change to this one.

```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <changelog>
        <model>
            <version>2.0</version>
            <owner>Shanu7002</owner>
            <description>BREAKING: Added mandatory newField to the schema</description>
            <actualModel>
                A Json trying to recreate the model in firebase ex:
                    user = {
                        id: --gerado automaticamente  28-character strings (Base62)
                        name: string
                        email: string
                        type: UserType enum
                        createdAt: string (iso8601) - horario do dispositivo para nao se preocupar com ztimestamp convertion
                        newField: string
                    }
            </actualModel>
        </model>
    </changelog>
```

## Minor Change

A Minor change requires you to update the version to the next decimal number, you as owner and new model.

This change log

```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <changelog>
        <model>
            <version>1.0</version>
            <owner>XXX</owner>
            <description>Initial model creation</description>
            <actualModel>
                A Json trying to recreate the model in firebase ex:
                    user = {
                        id: --gerado automaticamente  28-character strings (Base62)
                        name: string
                        email: string
                        type: UserType enum
                        createdAt: string (iso8601) - horario do dispositivo para nao se preocupar com ztimestamp convertion
                    }
            </actualModel>
        </model>
    </changelog>
```

Gonna change to this one.

```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <changelog>
        <model>
            <version>1.1</version>
            <owner>Shanu7002</owner>
            <description>Added a new helper function for JSON parsing; schema remains unchanged.</description>
            <actualModel>
                A Json trying to recreate the model in firebase ex:
                    user = {
                        id: --gerado automaticamente  28-character strings (Base62)
                        name: string
                        email: string
                        type: UserType enum
                        createdAt: string (iso8601) - horario do dispositivo para nao se preocupar com ztimestamp convertion
                    }

                    Added a new function to parse json
            </actualModel>
        </model>
    </changelog>
```
