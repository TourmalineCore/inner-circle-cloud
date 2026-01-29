apply:
	cd ./start-vm-function && zip function-js.zip ./index.js ./package.json

	cd ./stop-vm-function && zip function-js.zip ./index.js ./package.json

	terraform apply

apply-auto-approve:
	cd ./start-vm-function && zip function-js.zip ./index.js ./package.json

	cd ./stop-vm-function && zip function-js.zip ./index.js ./package.json

	terraform apply --auto-approve