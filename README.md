# CMR Visual Recognition & Warehouse Automation

[![Project Status: Alpha](https://img.shields.io/badge/status-alpha-orange.svg)](#)
[![ABAP](https://img.shields.io/badge/Language-ABAP-blue.svg)](#)
[![Platform](https://img.shields.io/badge/Platform-SAP%20BTP%20%7C%20On--Premise-blue)](#)
[![Built with: abapGit](https://img.shields.io/badge/built%20with-abapGit-green.svg)](https://abapgit.org)

> ⚠️ **Development Status (Pre-Release):** This repository contains a functional demonstration application built for the **Agent Integration Processing Framework (AIPF)**. The framework and this demo are currently under active development. APIs, database schemas, and tool definitions are subject to change. Feedback and early contributions are highly welcome!

> 🛠️ **Ecosystem Integration:** This framework is designed and intended to be used in conjunction with the official **[ABAP AI SDK](https://help.sap.com/docs/abap-ai/generative-ai-in-abap-cloud/api-reference-guide-for-abap-ai-sdk)**. It relies on the SDK's standard enterprise capabilities to securely handle Generative AI communication layers within ABAP Cloud environments.

This is a comprehensive blueprint application showcasing how multimodal AI can be integrated directly into core SAP enterprise workflows using the [AIPF Core Framework](https://github.com/IlyaPrusakou/aipf.git).

---

<img width="1000" height="636" alt="image" src="https://github.com/user-attachments/assets/aa7aceae-f1c5-45cc-9267-bfa5c9728a67" />

---

## Prerequisites

To import and execute this demo application, your environment must meet the following requirements:
* **SAP Environment**: SAP BTP ABAP Environment, S/4HANA Private Cloud, or S/4HANA On-Premise system.
* **Development Tools**: ABAP Development Tools (ADT) in Eclipse.
* **Git Client**: [abapGit](https://abapgit.org) configured in your target system.

## Installation & Setup

### 1. Install Core AIPF Framework
Before deploying the demo agent, you must pull and activate the core framework:
1. Open abapGit and create a new **Online Repository** with the URL: `https://github.com/IlyaPrusakou/aipf.git`
2. Pull the objects into your development system.
3. Activate the objects sequentially (refer to the core AIPF repository documentation for specific dictionary and RAP activation sequences).

### 2. Base Framework Initialization
Execute the setup classes provided by the core framework to instantiate necessary configurations:
1. Run class `ZPRU_CL_SNRO_INTERVALS` to generate number range intervals for object `ZPRU_AXCHD`.
2. Run class `ZPRU_CL_TEST_DATA` to initialize the core agent type entry (`AGTYP1`).

### 3. Install Demo Agent
1. Install demo agent: `https://github.com/IlyaPrusakou/aipf-demo-visual-recognition.git`
2. Create agent `DOC_VISUAL_RECOGNITION` and its tools via `ZPRU_CL_DOC_VIS_TEST_DATA`

## Configuration State
Eventually, you will receive the following definition of vision recognition agent:
1. Agent Type Table `ZPRU_AGENT_TYPE`:

<img width="1112" height="122" alt="image" src="https://github.com/user-attachments/assets/30f098ee-2ad6-467d-bf4f-63cf714f231c" />

---

2. Agent Definition Table `ZPRU_AGENT`:

<img width="1630" height="125" alt="image" src="https://github.com/user-attachments/assets/baa159b1-8716-4f49-81e5-8c48fab24c30" />

---

3. Agent Tools Definition Table `ZPRU_AGENT_TOOL`:

<img width="1480" height="257" alt="image" src="https://github.com/user-attachments/assets/42a47a36-dccb-49db-bb67-98d830c70157" />

---

# Document Vision Agent — User Experience

## What Is It?

The **Document Vision Agent** is a smart assistant that can look at scanned shipping documents (like a CMR waybill), read the information from them, and automatically perform all the warehouse follow-up tasks — without any manual data entry.

Think of it as a digital warehouse clerk who can glance at a paper document, understand everything on it, and then take care of all the necessary steps to process the shipment.

---

## How It Works (Demo Experience)

### Step 1: Upload a Scanned Document
You provide a scanned CMR document (a standard international shipping waybill) as an image. The agent accepts the image through a simple interface — you just attach the picture and send.

### Step 2: The Agent "Reads" the Document
Behind the scenes, the agent's AI looks at the image just like a human would. It reads:
- Who sent the goods (sender/shipper info)
- Who receives them (consignee)
- Who is transporting them (carrier)
- Where the goods are picked up and delivered
- What items are in the shipment (description, weight, quantity)
- Any special markings like hazard warnings

### Step 3: Automated Warehouse Processing
Once the document is understood, the agent automatically performs a complete end-to-end warehouse workflow:

| What Happens | Why It Matters |
|---|---|
| **CMR Record Created** | The document details are saved in the system as a formal CMR record |
| **Dangerous Goods Checked** | Items are scanned for hazardous materials (chemicals, explosives, flammable goods, etc.) — any risks are flagged immediately |
| **Data Validated** | The agent checks that all required fields are filled in correctly and flags anything missing or wrong |
| **Inbound Delivery Created** | The shipment is converted into an inbound delivery order, ready for the warehouse team |
| **Storage Found** | The system checks which warehouse storage bins are available and free |
| **Putaway Task Generated** | A warehouse task is created telling staff exactly where to store each item |

### Step 4: Results You Can See
At the end, you get a clear summary showing:
- ✅ The CMR document has been created and saved
- ⚠️ Any dangerous goods alerts (if hazardous items were detected)
- ✅ / ❌ Validation status (whether the document is complete and correct)
- 📦 The inbound delivery is ready
- 📍 Suggested storage locations
- 🔧 Warehouse tasks have been created

Everything is persisted in the system — no data is lost, and you can always look up past processing results.

---

## What Makes It Special from a User's Perspective?

| Feature | Benefit |
|---|---|
| **One-click document processing** | No manual typing. Just upload an image and everything is handled automatically |
| **End-to-end automation** | From a scanned paper to warehouse tasks in one seamless flow |
| **Dangerous goods detection** | Automatic safety checks — no risk of missing hazardous material labels |
| **Data validation** | Catches errors and missing fields before they cause problems downstream |
| **Everything saved in the system** | All results are stored in SAP, fully auditable and traceable |
| **Complex workflow** | What would take a human clerk 15-20 minutes happens almost instantly |

---

## In Simple Terms

> **"Upload a scanned shipping document → Get a fully processed inbound delivery with warehouse tasks, safety checks, and validation — no manual work required."**

The Document Vision Agent turns a paper document into a complete digital warehouse workflow in seconds.




# Visual Recognition Agent — Technical Summary

## Overview

The **Visual Recognition Agent** is a demonstration agent built on top of the **AIPF (Agent Integration Processing Framework)** core framework. It showcases a complete warehouse document processing workflow using multimodal AI (ABAP AI SDK) for document understanding, combined with pure ABAP logic for business processing, validation, and persistence via SAP RAP (RESTful Application Programming).

The agent is registered in the AIPF framework under the name **`DOC_VISUAL_RECOGNITION`** with agent type `AGTYP1`.

---

## Architecture

### Single Unified Class — `ZPRU_CL_COMPUTER_VISION`

The agent is implemented as a single main class that acts as a **facade**, delegating all AIPF framework interface implementations to **local classes (local types)** defined within the same source file. This means a single class handles all the plug-in points required by the AIPF framework:

| AIPF Interface | Delegated To |
|---|---|
| `ZPRU_IF_DECISION_PROVIDER` | `lcl_adf_decision_provider` |
| `ZPRU_IF_SHORT_MEMORY_PROVIDER` | `lcl_adf_short_memory_provider` |
| `ZPRU_IF_LONG_MEMORY_PROVIDER` | `lcl_adf_long_memory_provider` |
| `ZPRU_IF_AGENT_INFO_PROVIDER` | `lcl_adf_agent_info_provider` |
| `ZPRU_IF_PROMPT_PROVIDER` | `lcl_adf_syst_prompt_provider` |
| `ZPRU_IF_AGENT_MAPPER` | `lcl_adf_agent_mapper` |
| `ZPRU_IF_TOOL_PROVIDER` | `lcl_adf_tool_provider` |
| `ZPRU_IF_TOOL_INFO_PROVIDER` | `lcl_adf_tool_info_provider` |
| `ZPRU_IF_TOOL_SCHEMA_PROVIDER` | `lcl_adf_schema_provider` |

This design pattern centralizes all agent logic within one ABAP class, reducing the number of persisted ABAP classes needed in the database, while keeping clean separation of concerns via local types.

---

## Decision Provider — `lcl_adf_decision_provider`

This is the **brain** of the agent, inheriting from `ZPRU_CL_DECISION_PROVIDER`. Its `process_thinking` method executes the following workflow:

### 1. Input Handling
- Receives an input payload containing **messages with attached images** (scanned CMR documents in JPEG format, Base64-encoded).
- Deserializes the JSON input into structured ABAP types.

### 2. Multimodal LLM Call — ABAP AI SDK

* **Prepares an Intelligent Scenario Request container via the standard SDK factory:**
    * **System Instructions:** Passes framework-level business rules (always use USD, KG, M3), execution schema constraints, and output formatting rules into the container via `lo_messages->set_system_role(...)`.
    * **Multimodal Attachment Parsing:** Converts each attached JPEG file (scanned CMR waybills) to an inline Base64 payload, mapping them structurally alongside textual prompt instructions inside the SDK container.
* **Orchestrates execution safely through SAP AI Core:** Executes the remote orchestration request securely using the immutable `cl_aic_islm_compl_api_factory` pattern inside ABAP Cloud, routing the pipeline dynamically via standard SAP service destination layers.
* **Captures and structuralizes the outcome context:** Receives a structured JSON payload directly back from the model response via `lo_response->get_completion()`, allowing the framework to extract raw header/item data safely from the scanned document image for transactional validation phases.

### 3. Execution Plan Generation
After the LLM thinking phase, the agent defines a **fixed 6-step execution plan** (deterministic orchestration):

| Step | Tool Name | Description |
|---|---|---|
| 1 | `CREATE_CMR` | Parse extracted CMR JSON & persist via RAP |
| 2 | `CLASSIFY_DANGER_GOODS` | Detect hazardous materials |
| 3 | `VALIDATE_CMR` | Validate mandatory fields & business rules |
| 4 | `CREATE_INB_DELIVERY` | Map CMR → inbound delivery |
| 5 | `FIND_STORAGE_BIN` | Query available storage bins |
| 6 | `CREATE_WAREHOUSE_TASK` | Generate putaway warehouse tasks |

---

## Tools (6 ABAP Code Executors)

Each tool is an **ABAP Code Executor** (inherits `ZPRU_CL_ABAP_EXECUTOR`), meaning the tool's logic is pure ABAP code, not an LLM call. The tools pass data between each other via **context fields** (key-value pairs) that flow through the agent execution pipeline.

### Tool 1: `CREATE_CMR` — `lcl_adf_create_cmr`
- **Input**: `CMRCREATIONCONTENT` (JSON string with LLM-extracted headers and items)
- **Logic**:
  1. Deserialize creation content from JSON
  2. Assign sequential CMR IDs by querying max ID from `ZR_PRU_CMR_HEADER`
  3. Prepare RAP entities for CMR header (`ZRPUCMRHEADER`) and items (`ZRPUCMRITEM`)
  4. Persist via `MODIFY ENTITIES` RAP operation
  5. Read back created entities and map to context
- **Output context fields**: `CMRHEADERS` (JSON), `CMRITEMS` (JSON), `CMRCREATIONCONTENT` (JSON)

### Tool 2: `CLASSIFY_DANGER_GOODS` — `lcl_adf_classify_danger_goods`
- **Input**: `CMRITEMS` (JSON with item data)
- **Logic**:
  1. Deserialize CMR items from context
  2. For each item, check dangerous goods via multiple heuristics in priority order:
     - **Explicit**: Hazard class field → alert if populated
     - **Explicit**: UN number field → alert if populated
     - **Free-text heuristics on Nature of Goods**: Checks against keyword lists for 10 DG categories:
       - Explosive (EXPLOS, etc.)
       - Flammable Gas (LPG, LNG, PROPANE, ACETYLENE, HYDROGEN...)
       - Flammable Liquid (PETROL, DIESEL, ETHANOL, BENZENE...)
       - Flammable Solid (PHOSPHORUS, SULPHUR, MAGNESIUM...)
       - Oxidiser/Peroxide (PEROXIDE, CHLORATE, NITRATE...)
       - Toxic (POISON, CYANIDE, MERCURY, CHLORINE...)
       - Infectious (PATHOGEN, MEDICAL WASTE...)
       - Radioactive (NUCLEAR, URANIUM, PLUTONIUM...)
       - Corrosive (ACID, CAUSTIC, SULPHURIC...)
       - Other Hazardous (LITHIUM BATTERY, DRY ICE...)
  3. Create alert entities with type `DANGER_GOODS` and persist via RAP (`ZRPUCMRALERT`)
- **Output context fields**: `CMRALERTS` (JSON with alert data)

### Tool 3: `VALIDATE_CMR` — `lcl_adf_validate_cmr`
- **Input**: `CMRHEADERS`, `CMRITEMS`, `CMRCREATIONCONTENT` (JSON)
- **Logic**:
  1. Deserialize headers and items
  2. Run validation checks:
     - **Header-level**: Sender info, consignee info, carrier info, taking-over place, delivery place, taking-over date, currency (when cash on delivery), item count
     - **Item-level**: Nature of goods, gross weight, weight unit
     - **DG fields**: UN number, hazard class, packing group (when relevant)
  3. Create **findings** with status `INCOMPLETE` or `INVALID`
  4. Persist findings via RAP (`ZRPUCMRVALID`)
  5. Calculate **overall CMR status**: `VALID` / `INCOMPLETE` / `INVALID`
- **Output context fields**: `CMRSTATUS` (JSON), `CMRFINDING` (JSON)

### Tool 4: `CREATE_INB_DELIVERY` — `lcl_adf_create_inb_delivery`
- **Input**: `CMRHEADERS`, `CMRITEMS`, `CMRCREATIONCONTENT` (JSON)
- **Logic**:
  1. Deserialize CMR data
  2. Map CMR → inbound delivery structures:
     - CMR ID → delivery reference
     - Sender info → vendor
     - Consignee → consignee
     - Delivery place → arrival place
     - Taking-over date → delivery date
     - Item position, nature of goods, quantity, weight, hazard class → item fields
  3. Generate sequential delivery IDs
  4. Persist via RAP (`INBHDR` / `INBITM`)
- **Output context fields**: `INBDELIVERYHEADERS` (JSON), `INBDELIVERYITEMS` (JSON)

### Tool 5: `FIND_STORAGE_BIN` — `lcl_adf_find_storage_bin`
- **Logic**: Simple database query — `SELECT FROM zprustorbin WHERE is_blocked = abap_false` ordered by bin ID
- **Output context fields**: `STORAGEBINS` (JSON with all available bins)

### Tool 6: `CREATE_WAREHOUSE_TASK` — `lcl_adf_create_warehouse_task`
- **Input**: `INBDELIVERYHEADERS`, `INBDELIVERYITEMS`, `STORAGEBINS` (JSON)
- **Logic**:
  1. Deserialize all input contexts
  2. For each inbound item, build a warehouse task entity:
     - Source bin: `RECEIVING`
     - Destination bin: first available (non-blocked) storage bin
     - Confirmation status: `O` (Open)
  3. Generate sequential task numbers via `SELECT MAX(tanum)`
  4. Persist via RAP (`TASK`)
- **Output context fields**: `WAREHOUSETASKS` (JSON)

---

## Interface — `ZPRU_IF_COMPUTER_VISION`

The central interface defines all **type structures**, **context field constants**, and **tool schemas** for the agent:

### Key Constants
- `CS_TOOLS`: Maps tool names (`CREATE_CMR`, `CLASSIFY_DANGER_GOODS`, `VALIDATE_CMR`, `CREATE_INB_DELIVERY`, `FIND_STORAGE_BIN`, `CREATE_WAREHOUSE_TASK`)
- `CS_CONTEXT_FIELD`: Maps context field names to their ABAP type absolute names (e.g., `CMRHEADERS`, `CMRITEMS`, `CMRALERTS`, `STORAGEBINS`, etc.)
- `CS_INPUT_TOOL_STRUCTURE`: Maps each tool to its expected input ABAP structure type
- `CS_INPUT_CONTEXT_FIELDS` / `CS_OUTPUT_CONTEXT_FIELDS`: Defines which context fields each tool consumes/produces

### Key Types
- **CMR types**: `ZS_CMR_CREATE_REQUEST` (tool1 input), `TS_CMR_CLASSIFY_REQ` (tool2 input), `TS_CMR_VALIDATE_REQ` (tool3 input)
- **Inbound delivery types**: `TS_INB_DELIVERY_CREATE_REQUEST` (tool4 input)
- **Storage bin types**: `TS_FIND_STORAGE_BIN_REQUEST` (tool5 input)
- **Warehouse task types**: `TS_CREATE_WHSE_TASK_REQUEST` (tool6 input)
- **Context field types**: Alert, Header, Item, Status, Finding, Inbound Delivery, Storage Bin, Warehouse Task structures

---

## Memory Management

The agent uses **framework base classes** for memory:
- **Short Memory Provider**: `lcl_adf_short_memory_provider` → inherits `ZPRU_CL_SHORT_MEMORY_BASE` (default behavior)
- **Long Memory Provider**: `lcl_adf_long_memory_provider` → inherits `ZPRU_CL_LONG_MEMORY_BASE` (default behavior)

Both are managed as **singletons** via `ZPRU_IF_AGENT_SINGLETON_METH` to ensure state is preserved across framework callbacks during an execution.

---

## System Prompt — `lcl_adf_syst_prompt_provider`

Provides a structured system prompt with:
- **Primary session task**: Full document → warehouse workflow description
- **Business rules**: Currency (USD), weight (KG), volume (M3), mandatory fields, DG compliance
- **Technical rules**: API timeout (30s), Base64 encoding, max image size (20MB)
- **Format guidelines**: No markdown, valid JSON only, strict schema adherence, no conversational text, canonical units, mask sensitive data, error format
- **Reasoning steps**: 5-step chain-of-thought (extract fields → normalize → classify DG → validate → check schema)
- **Prompt restrictions**: No hallucination, no execution outside tools, only structured output

---

## Agent Info — `lcl_adf_agent_info_provider`

Provides comprehensive agent metadata:
- **Name**: Document Visual Recognition Agent v1.0.0
- **Role**: Extracts structured data from CMR documents, detects dangerous goods, creates CMR and inbound delivery records, validates fields, and orchestrates warehouse tasks
- **Domains**: Document OCR & Data Extraction, Dangerous Goods Classification, Inbound Delivery Automation, Warehouse Tasking & Storage, Validation & Compliance
- **Goals**: Accurate document extraction, dangerous goods detection, inbound delivery creation, validation and remediation guidance
- **Restrictions**: Read-only access for past records, no financial transactions

---

## Data / RAP Business Objects

The demo includes a complete set of RAP business objects:

| Business Object | Package | Description |
|---|---|---|
| `ZR_PRU_CMR_HEADER` | `ZPRU_DEMO_CMR` | CMR header with items (header-composition) |
| `ZR_PRU_CMR_VALID` | `ZPRU_DEMO_FINDING` | Validation findings for CMR |
| `ZR_PRU_CMR_ALERT` | `ZPRU_DEMO_ALERT` | Dangerous goods alerts |
| `ZPRUR_INBHDR` | `ZPRU_DEMO_INB_DELIVERY` | Inbound delivery header with items |
| `ZPRUR_STORBIN` | `ZPRU_DEMO_STOR_BIN` | Storage bin master data |
| `ZPRUR_TASK` | `ZPRU_DEMO_WHS_TASK` | Warehouse tasks |

Each object follows the standard RAP pattern with CDS views, behavior definitions, and behavior implementations.

---

## Execution Flow Summary

```
User Input (Message + Scanned CMR Image)
  │
  ▼
[1] DECISION PROVIDER (Thinking Phase)
    │  ├─ Deserialize input payload (message + image attachments)
    │  ├─ Build ABAP AI SDK request (system + schema + base64 images)
    │  ├─ Call ABAP AI SDK → Extract JSON with headers/items
    │  └─ Generate Execution Plan (6 fixed steps)
    │
    ▼
[2] EXECUTION PLAN LOOP (6 Steps)
    │
    ├─ Step 1: CREATE_CMR ──────────── Persist CMR header+items via RAP
    │     Output → CMRHEADERS, CMRITEMS, CMRCREATIONCONTENT
    │
    ├─ Step 2: CLASSIFY_DANGER_GOODS ─ Check items for hazardous materials
    │     Output → CMRALERTS
    │
    ├─ Step 3: VALIDATE_CMR ────────── Validate mandatory fields
    │     Output → CMRSTATUS, CMRFINDING
    │
    ├─ Step 4: CREATE_INB_DELIVERY ─── Map CMR → inbound delivery via RAP
    │     Output → INBDELIVERYHEADERS, INBDELIVERYITEMS
    │
    ├─ Step 5: FIND_STORAGE_BIN ────── Query available storage bins
    │     Output → STORAGEBINS
    │
    └─ Step 6: CREATE_WAREHOUSE_TASK ─ Generate putaway tasks via RAP
          Output → WAREHOUSETASKS
    │
    ▼
[3] FINAL RESPONSE (set_final_response_content)
    ├─ Read execution data (headers, queries, steps from AXC service)
    ├─ Assign runtime metadata to messages
    ├─ Build recognition output (message + run + query + steps)
    └─ Append freshest context (latest key-value pairs)
```

---

# Contributing & Feedback

Since this project is in its early stages, community insights are invaluable. 

* **Found a Bug?** Open an [Issue](https://github.com/IlyaPrusakou/aipf-demo-visual-recognition/issues).
* **Want to Discuss Features?** Feel free to initiate a thread in GitHub Discussions regarding agentic workflows in ABAP.
* **Contributions**: Pull requests are welcome! If you plan to make significant architectural modifications, please open an issue first to discuss your intended changes.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

