// ref: https://yandex.cloud/en/docs/compute/tutorials/nodejs-cron-restart-vm?#zip-archive
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
  // status 2 is RUNNING
  // https://github.com/yandex-cloud/nodejs-sdk/blob/45b3aba15623c30037afafd761946faae51cad00/src/generated/yandex/cloud/compute/v1/instance.ts#L160
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
