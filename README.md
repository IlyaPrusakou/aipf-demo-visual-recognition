# aipf-demo
Demo app

Prerequisites:
1 BTP, on-premise, private cloud system
2 ADT Tools in Eclipse
3 abapGit

How to try this demo:
1 install core framework via abapGit clonning https://github.com/IlyaPrusakou/aipf.git
2 run in ADT for Eclipse class ZPRU_CL_SNRO_INTERVALS to create number range intervals for object 'ZPRU_AXCHD'
3 run in ADT for Eclipse class ZPRU_CL_TEST_DATA to create agent type entry 'AGTYP1'
4 install demo agent via abapGit clonning https://github.com/IlyaPrusakou/aipf-demo-visual-recognition.git
5 run in ADT for Eclipse class ZPRU_CL_DOC_VIS_TEST_DATA to create agent 'DOC_VISUAL_RECOGNITION' and its tools

Eventually, you will recieve the following definition of vision recognition agent:
1. Agent Type Table ZPRU_AGENT_TYPE:
<img width="1112" height="122" alt="image" src="https://github.com/user-attachments/assets/30f098ee-2ad6-467d-bf4f-63cf714f231c" />
2 Agent Definition Table ZPRU_AGENT:
<img width="1630" height="125" alt="image" src="https://github.com/user-attachments/assets/baa159b1-8716-4f49-81e5-8c48fab24c30" />
3 Agent Tools Definition Table ZPRU_AGENT_TOOL:
<img width="1480" height="257" alt="image" src="https://github.com/user-attachments/assets/42a47a36-dccb-49db-bb67-98d830c70157" />















1 copy agent template
2 create agent definition

The Agent defintion:
<img width="1818" height="795" alt="image" src="https://github.com/user-attachments/assets/084fc641-679c-4e95-91c8-31e5de2c72cd" />
3 delete redundant classes for different type of tools from template
4 create structure for input as dictionary structure
<img width="856" height="282" alt="image" src="https://github.com/user-attachments/assets/cea15dd1-6809-40ca-a26f-d5465c472b36" />


