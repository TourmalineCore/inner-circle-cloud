import { serviceClients, Session, cloudApi } from '@yandex-cloud/nodejs-sdk';

const {
  compute: {
    instance_service: {
      ListInstancesRequest,
      GetInstanceRequest,
      StopInstanceRequest,
    },
    instance: {
      IpVersion,
    },
  },
} = cloudApi;

const FOLDER_ID = process.env.FOLDER_ID;
const INSTANCE_ID = process.env.INSTANCE_ID;

export const handler = async function (event, context) {
  const session = new Session();
  const instanceClient = session.client(serviceClients.InstanceServiceClient);
  const list = await instanceClient.list(ListInstancesRequest.fromPartial({
    folderId: FOLDER_ID,
  }));
  const state = await instanceClient.get(GetInstanceRequest.fromPartial({
    instanceId: INSTANCE_ID,
  }));

  var status = state.status

  if (status == 2){
    const stopcommand = await instanceClient.stop(StopInstanceRequest.fromPartial({
      instanceId: INSTANCE_ID,
    }));
  }

  return {
    statusCode: 200,
    body: {
      status
    }
  };
};
