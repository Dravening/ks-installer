function wait_status_ok(){
    for ((n=0;n<30;n++))
    do  
        OK=`kubectl get pod -A| grep -E 'Running|Completed' | wc | awk '{print $1}'`
        Status=`kubectl get pod -A | sed '1d' | wc | awk '{print $1}'`
        echo "Success rate: ${OK}/${Status}"
        if [[ $OK == $Status ]]
        then
            n=$((n+1))
        else
            n=0
        fi
        sleep 10
        kubectl get all -A
    done
}

yum install -y vim openssl socat conntrack ipset wget
curl -sfL https://get-kk.d3os.io | VERSION=v1.1.0 sh -
chmod +x kk
echo "yes" | ./kk create cluster --with-kubernetes v1.20.4

kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
wait_status_ok
kubectl patch storageclass openebs-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

kubectl apply -f https://raw.githubusercontent.com/d3os/ks-installer/master/deploy/d3os-installer.yaml
kubectl apply -f https://raw.githubusercontent.com/d3os/ks-installer/master/deploy/cluster-configuration.yaml

kubectl -n d3os-system get cc ks-installer -o yaml | sed "s/false/true/g" | kubectl replace -n d3os-system cc -f -

kubectl -n d3os-system patch cc ks-installer --type merge --patch '{"spec":{"etcd":{"monitoring":false}}}'
kubectl -n d3os-system patch cc ks-installer --type merge --patch '{"spec":{"etcd":{"tlsEnable":false}}}'

kubectl -n d3os-system rollout restart deploy ks-installer